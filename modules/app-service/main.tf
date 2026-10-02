resource "azurerm_service_plan" "this" {
  name                = "asp-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  # B1 is the cheapest tier with VNet integration and Always On.
  sku_name = "B1"
  tags     = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true

  # Outbound traffic goes through the VNet, so the SQL service endpoint applies.
  virtual_network_subnet_id = var.subnet_id

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  # Resolve @Microsoft.KeyVault(...) app settings with the user-assigned identity.
  key_vault_reference_identity_id = var.identity_id

  site_config {
    always_on           = true
    ftps_state          = "Disabled"
    minimum_tls_version = "1.2"
    http2_enabled       = true

    application_stack {
      node_version = "24-lts"
    }
  }

  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.app_insights_connection_string
    # The connection string only says where telemetry goes; this turns on
    # App Service's codeless agent (~3 = Linux) so requests, dependencies
    # (e.g. SQL calls) and exceptions are actually collected.
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
    # DefaultAzureCredential picks the right identity from this.
    AZURE_CLIENT_ID = var.identity_client_id
    # Key Vault reference: App Service fetches the secret at runtime.
    GREETING     = "@Microsoft.KeyVault(SecretUri=${var.greeting_secret_id})"
    SQL_SERVER   = var.sql_server_fqdn
    SQL_DATABASE = var.sql_database_name
  }

  tags = var.tags

  lifecycle {
    # Azure adds this tag itself to link the web app to App Insights in the
    # portal. Without this, every plan would try to remove it.
    ignore_changes = [tags["hidden-link: /app-insights-resource-id"]]
  }
}
