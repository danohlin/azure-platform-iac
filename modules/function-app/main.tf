# Flex Consumption (FC1) is the current serverless plan for Functions; the
# older Linux Consumption (Y1) plan is being retired.
resource "azurerm_service_plan" "this" {
  name                = "asp-func-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "FC1"
  tags                = var.tags
}

resource "azurerm_function_app_flex_consumption" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true

  # Code packages are pulled from a blob container using the managed
  # identity - no storage keys anywhere.
  storage_container_type            = "blobContainer"
  storage_container_endpoint        = var.deployments_container_endpoint
  storage_authentication_type       = "UserAssignedIdentity"
  storage_user_assigned_identity_id = var.identity_id

  runtime_name           = "node"
  runtime_version        = "24"
  instance_memory_in_mb  = 2048
  maximum_instance_count = 40

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  site_config {
    application_insights_connection_string = var.app_insights_connection_string
  }

  app_settings = {
    # Identity-based host storage (replaces the AzureWebJobsStorage connection string).
    AzureWebJobsStorage__accountName = var.storage_account_name
    AzureWebJobsStorage__credential  = "managedidentity"
    AzureWebJobsStorage__clientId    = var.identity_client_id
    AZURE_CLIENT_ID                  = var.identity_client_id
  }

  tags = var.tags
}
