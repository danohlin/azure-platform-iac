output "server_fqdn" {
  value = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "database_name" {
  value = azurerm_mssql_database.app.name
}

output "admin_password_secret_name" {
  value = azurerm_key_vault_secret.admin_password.name
}
