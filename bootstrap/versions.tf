terraform {
  required_version = ">= 1.15, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.6"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }

  # Bootstrap deliberately uses local state: it creates the storage account
  # that every other configuration uses as its backend. The state file is
  # gitignored.
}

provider "azurerm" {
  subscription_id = var.subscription_id

  # azurerm 5.x no longer auto-registers resource providers.
  resource_providers_to_register = ["Microsoft.Storage"]

  features {}
}
