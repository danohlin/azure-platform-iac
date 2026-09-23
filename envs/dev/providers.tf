provider "azurerm" {
  subscription_id = var.subscription_id

  # azurerm 5.x registers nothing by default; list what this config uses.
  resource_providers_to_register = [
    "Microsoft.App",
    "Microsoft.Consumption",
    "Microsoft.ContainerRegistry",
    "Microsoft.Insights",
    "Microsoft.KeyVault",
    "Microsoft.ManagedIdentity",
    "Microsoft.Network",
    "Microsoft.OperationalInsights",
    "Microsoft.Sql",
    "Microsoft.Storage",
    "Microsoft.Web",
  ]

  # Storage accounts have key access disabled, so data-plane calls use Entra ID.
  storage_use_azuread = true

  features {
    key_vault {
      # Destroy fully removes the vault (and its secrets) instead of leaving
      # it soft-deleted, so destroy/apply cycles stay clean.
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }

    log_analytics_workspace {
      # Workspaces are soft-deleted for 14 days and their name stays reserved,
      # which blocks recreating the same name (especially in another region).
      permanently_delete_on_destroy = true
    }

    resource_group {
      # Azure auto-creates resources Terraform doesn't track (App Insights'
      # "Smart Detection" action group and a portal dashboard). This is a
      # throwaway learning environment, so let destroy delete them along with
      # the RG. Set to true for anything long-lived.
      prevent_deletion_if_contains_resources = false
    }
  }
}
