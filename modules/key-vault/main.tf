resource "azurerm_key_vault" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  # Access is granted with Azure RBAC roles, not vault access policies.
  rbac_authorization_enabled = true

  # Learning setup: short soft-delete and no purge protection so the vault
  # can be destroyed and recreated freely. Enable purge protection for real.
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = var.tags
}

# Deployer manages secrets (Terraform writes them below and in the SQL module).
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.deployer_object_id
}

# Workload identity can only read secrets.
resource "azurerm_role_assignment" "workload_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.workload_principal_id
}

# RBAC assignments take a while to propagate; writing a secret immediately
# after granting the role fails with 403.
resource "time_sleep" "rbac_propagation" {
  create_duration = "60s"

  depends_on = [
    azurerm_role_assignment.deployer_secrets_officer,
    azurerm_role_assignment.workload_secrets_user,
  ]
}

# Harmless demo value surfaced in the web app through a Key Vault reference.
resource "azurerm_key_vault_secret" "greeting" {
  name         = "app-greeting"
  value        = "Hello from Key Vault"
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [time_sleep.rbac_propagation]
}
