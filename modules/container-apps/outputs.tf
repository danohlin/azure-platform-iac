output "url" {
  value = "https://${azurerm_container_app.hello.ingress[0].fqdn}"
}

output "environment_id" {
  value = azurerm_container_app_environment.this.id
}
