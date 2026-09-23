output "url" {
  value = "https://${azurerm_function_app_flex_consumption.this.default_hostname}"
}

output "name" {
  value = azurerm_function_app_flex_consumption.this.name
}
