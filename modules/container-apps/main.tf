resource "azurerm_container_app_environment" "this" {
  name                = "cae-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  # azurerm 5.x: logs_destination must be set explicitly to ship to Log Analytics.
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = var.log_analytics_id

  # With a subnet: VNet-injected (the workload-profiles environment type only
  # needs a /27). Without one: Azure manages the network. Ingress is public
  # either way; the Consumption profile bills per use.
  infrastructure_subnet_id = var.subnet_id

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  tags = var.tags

  lifecycle {
    # Azure creates and names this managed RG itself.
    ignore_changes = [infrastructure_resource_group_name]
  }
}

resource "azurerm_container_app" "hello" {
  name                         = "ca-hello-${var.name_suffix}"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = azurerm_container_app_environment.this.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  # Wired up so you can swap the image below for one pushed to your ACR;
  # pulls authenticate with the managed identity (AcrPull).
  registry {
    server   = var.acr_login_server
    identity = var.identity_id
  }

  ingress {
    external_enabled = true
    target_port      = 80

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    # Scale to zero when idle - costs nothing between requests.
    min_replicas = 0
    max_replicas = 2

    container {
      name   = "hello"
      image  = var.image
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        value = var.app_insights_connection_string
      }
    }
  }

  tags = var.tags
}
