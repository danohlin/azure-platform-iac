resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"

  # No shared admin username/password; pulls use the managed identity.
  admin_enabled = false

  tags = var.tags
}

resource "azurerm_role_assignment" "workload_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = var.workload_principal_id
}

# So you can `az acr login` and `docker push` with your own identity.
resource "azurerm_role_assignment" "deployer_push" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPush"
  principal_id         = var.deployer_object_id
}

resource "time_sleep" "rbac_propagation" {
  create_duration = "60s"

  depends_on = [
    azurerm_role_assignment.workload_pull,
    azurerm_role_assignment.deployer_push,
  ]
}
