resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  # Hard cap on ingestion so a noisy app can't run up the bill.
  daily_quota_gb = var.daily_quota_gb
  tags           = var.tags
}

# Workspace-based App Insights (classic mode is retired).
resource "azurerm_application_insights" "this" {
  name                = "appi-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = var.tags
}
