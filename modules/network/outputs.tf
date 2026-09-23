output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  value = {
    app            = azurerm_subnet.app.id
    container_apps = azurerm_subnet.container_apps.id
    data           = azurerm_subnet.data.id
  }
}
