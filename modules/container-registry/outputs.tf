output "id" {
  value = azurerm_container_registry.this.id
}

output "name" {
  value = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Only available once AcrPull has propagated, so image pulls succeed."
  value       = azurerm_container_registry.this.login_server
  depends_on  = [time_sleep.rbac_propagation]
}
