variable "subscription_id" {
  description = "Azure subscription to deploy into."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
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

variable "environment" {
  type    = string
  default = "dev"
}

variable "budget_amount" {
  description = "Monthly budget for the resource group."
  type        = number
  default     = 50
}

variable "budget_emails" {
  description = "Who gets budget alerts."
  type        = list(string)
}

variable "sql_entra_admin_login" {
  description = "Your Entra ID UPN; becomes the SQL server's Entra admin."
  type        = string
}

variable "client_ip" {
  description = "Your public IP, allowed through the SQL firewall. null to skip."
  type        = string
  default     = null
}
