resource "azurerm_storage_account" "this" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  # Entra ID auth only - no account keys or SAS. Everything that touches
  # this account (you, the function app) authenticates with RBAC.
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

# Flex Consumption function apps deploy their code package here.
resource "azurerm_storage_container" "deployments" {
  name                  = "function-deployments"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_storage_queue" "jobs" {
  name               = "jobs"
  storage_account_id = azurerm_storage_account.this.id
}

# Tier blobs in the data container to cool after 30 days, delete after 90.
resource "azurerm_storage_management_policy" "this" {
  storage_account_id = azurerm_storage_account.this.id

  rule {
    name    = "age-out-data"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["data/"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
        delete_after_days_since_modification_greater_than       = 90
      }
    }
  }
}

locals {
  # Blob Data Owner is what the Functions host needs for AzureWebJobsStorage.
  workload_roles = [
    "Storage Blob Data Owner",
    "Storage Queue Data Contributor",
  ]
}

resource "azurerm_role_assignment" "workload" {
  for_each = toset(local.workload_roles)

  scope                = azurerm_storage_account.this.id
  role_definition_name = each.value
  principal_id         = var.workload_principal_id
}

# Lets you browse blobs and queues in the portal / Storage Explorer with
# your own identity, since key-based access is disabled.
resource "azurerm_role_assignment" "deployer" {
  for_each = toset(["Storage Blob Data Contributor", "Storage Queue Data Contributor"])

  scope                = azurerm_storage_account.this.id
  role_definition_name = each.value
  principal_id         = var.deployer_object_id
}

resource "time_sleep" "rbac_propagation" {
  create_duration = "60s"

  depends_on = [
    azurerm_role_assignment.workload,
    azurerm_role_assignment.deployer,
  ]
}
