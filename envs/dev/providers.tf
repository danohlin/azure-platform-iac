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

    resource_group {
      # Container Apps creates resources Terraform doesn't track; fail
      # loudly rather than deleting them if they are still present.
      prevent_deletion_if_contains_resources = true
    }
  }
}
