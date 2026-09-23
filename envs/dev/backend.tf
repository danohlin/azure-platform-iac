# Partial backend config: the storage account details live in dev.tfbackend
# (gitignored; copy dev.tfbackend.example and fill it from bootstrap outputs).
#
#   terraform init -backend-config=dev.tfbackend
terraform {
  backend "azurerm" {}
}
