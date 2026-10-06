data "azurerm_client_config" "current" {}

# Suffix for names that must be globally unique (storage, KV, ACR, SQL, apps).
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

locals {
  name_suffix = "${var.prefix}-${var.environment}"
  # Compact form for resources that disallow hyphens (storage, ACR).
  compact = "${var.prefix}${var.environment}${random_string.suffix.result}"
  unique  = "${local.name_suffix}-${random_string.suffix.result}"

  deployer_object_id = data.azurerm_client_config.current.object_id
  tenant_id          = data.azurerm_client_config.current.tenant_id

  tags = {
    project     = var.prefix
    environment = var.environment
    managed_by  = "terraform"
  }
}

# --- Foundation ---------------------------------------------------------------

module "resource_group" {
  source = "../../modules/resource-group"

  name          = "rg-${local.name_suffix}"
  location      = var.location
  budget_amount = var.budget_amount
  budget_emails = var.budget_emails
  tags          = local.tags
}

module "network" {
  source = "../../modules/network"

  name_suffix         = local.name_suffix
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = local.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  name_suffix         = local.name_suffix
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = local.tags
}

module "identity" {
  source = "../../modules/identity"

  name_suffix         = local.name_suffix
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = local.tags
}

# --- Data & shared services ---------------------------------------------------

module "key_vault" {
  source = "../../modules/key-vault"

  name                  = "kv-${local.unique}"
  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location
  tenant_id             = local.tenant_id
  deployer_object_id    = local.deployer_object_id
  workload_principal_id = module.identity.principal_id
  tags                  = local.tags
}

module "storage" {
  source = "../../modules/storage"

  name                  = "st${local.compact}"
  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location
  deployer_object_id    = local.deployer_object_id
  workload_principal_id = module.identity.principal_id
  tags                  = local.tags
}

module "sql" {
  source = "../../modules/sql"

  name                  = "sql-${local.unique}"
  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location
  tenant_id             = local.tenant_id
  entra_admin_login     = var.sql_entra_admin_login
  entra_admin_object_id = local.deployer_object_id
  app_subnet_id         = module.network.subnet_ids.app
  client_ip             = var.client_ip
  key_vault_id          = module.key_vault.id
  tags                  = local.tags
}

module "container_registry" {
  source = "../../modules/container-registry"

  name                  = "cr${local.compact}"
  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location
  deployer_object_id    = local.deployer_object_id
  workload_principal_id = module.identity.principal_id
  tags                  = local.tags
}

# --- Compute ------------------------------------------------------------------

module "app_service" {
  source = "../../modules/app-service"

  name                           = "app-${local.unique}"
  name_suffix                    = local.name_suffix
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = module.network.subnet_ids.app
  identity_id                    = module.identity.id
  identity_client_id             = module.identity.client_id
  app_insights_connection_string = module.monitoring.app_insights_connection_string
  greeting_secret_id             = module.key_vault.greeting_secret_id
  sql_server_fqdn                = module.sql.server_fqdn
  sql_database_name              = module.sql.database_name
  tags                           = local.tags
}

module "container_apps" {
  source = "../../modules/container-apps"

  name_suffix         = local.name_suffix
  resource_group_name = module.resource_group.name
  # centralus kept returning ManagedEnvironmentCapacityHeavyUsageError, so the
  # environment runs in its own region. A VNet-injected environment must share
  # its VNet's region, so subnet_id is left unset (Azure-managed network) while
  # container_apps_location differs from location. snet-container-apps stays
  # for switching back.
  location                       = var.container_apps_location
  log_analytics_id               = module.monitoring.log_analytics_id
  identity_id                    = module.identity.id
  acr_login_server               = module.container_registry.login_server
  app_insights_connection_string = module.monitoring.app_insights_connection_string
  tags                           = local.tags
}

module "function_app" {
  source = "../../modules/function-app"

  name                           = "func-${local.unique}"
  name_suffix                    = local.name_suffix
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  storage_account_name           = module.storage.name
  deployments_container_endpoint = module.storage.deployments_container_endpoint
  identity_id                    = module.identity.id
  identity_client_id             = module.identity.client_id
  app_insights_connection_string = module.monitoring.app_insights_connection_string
  tags                           = local.tags
}
