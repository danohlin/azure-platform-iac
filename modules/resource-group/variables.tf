variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "budget_amount" {
  description = "Monthly budget for the resource group, in the billing currency."
  type        = number
}

variable "budget_emails" {
  description = "Addresses notified when budget thresholds are crossed."
  type        = list(string)
}
