resource "random_password" "admin" {
  length      = 24
  special     = true
  min_lower   = 2
  min_upper   = 2
  min_numeric = 2
  min_special = 2
  # Characters that survive connection strings and shells unescaped.
  override_special = "!#%*()-_=+[]"
}

resource "azurerm_mssql_server" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  minimum_tls_version          = "1.2"
  administrator_login          = "sqladmin"
  administrator_login_password = random_password.admin.result

  # Entra admin lets you (and later the apps' managed identity) connect
  # without a password. SQL auth stays on as a break-glass path; set
  # azuread_authentication_only = true to turn it off.
  azuread_administrator {
    login_username = var.entra_admin_login
    object_id      = var.entra_admin_object_id
    tenant_id      = var.tenant_id
  }

  tags = var.tags
}

# Basic DTU tier: 5 DTU / 2 GB, cheapest always-available option.
resource "azurerm_mssql_database" "app" {
  name         = "sqldb-app"
  server_id    = azurerm_mssql_server.this.id
  sku_name     = "Basic"
  max_size_gb  = 2
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  enclave_type = "Default"
  tags         = var.tags
}

# App Service reaches SQL through the app subnet's service endpoint instead
# of the "Allow Azure services" rule, which would admit any Azure tenant.
resource "azurerm_mssql_virtual_network_rule" "app" {
  name      = "allow-app-subnet"
  server_id = azurerm_mssql_server.this.id
  subnet_id = var.app_subnet_id
}

# Optional: your public IP, for connecting from SSMS / Azure Data Studio.
resource "azurerm_mssql_firewall_rule" "client" {
  count = var.client_ip == null ? 0 : 1

  name             = "allow-client-ip"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = var.client_ip
  end_ip_address   = var.client_ip
}

resource "azurerm_key_vault_secret" "admin_password" {
  name         = "sql-admin-password"
  value        = random_password.admin.result
  key_vault_id = var.key_vault_id
  content_type = "password"
}
