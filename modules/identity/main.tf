# One user-assigned identity shared by the compute services. It gets RBAC
# roles on Key Vault, Storage, and ACR in their respective modules, so the
# apps never need keys or passwords to reach them.
resource "azurerm_user_assigned_identity" "this" {
  name                = "id-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
