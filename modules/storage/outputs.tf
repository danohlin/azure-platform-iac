output "id" {
  value = azurerm_storage_account.this.id
}

output "name" {
  description = "Only available once RBAC has propagated, so the function app can start cleanly."
  value       = azurerm_storage_account.this.name
  depends_on  = [time_sleep.rbac_propagation]
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}

output "deployments_container_endpoint" {
  value = "${azurerm_storage_account.this.primary_blob_endpoint}${azurerm_storage_container.deployments.name}"
}
