variable "subscription_id" {
  description = "Azure subscription to deploy into."
  type        = string
}

variable "location" {
  description = "Azure region for the state storage account."
  type        = string
  default     = "eastus"
}

variable "prefix" {
  description = "Short project prefix used in resource names."
  type        = string
  default     = "azplat"

  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.prefix))
    error_message = "prefix must be 3-10 lowercase letters or digits."
  }
}
