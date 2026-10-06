variable "name_suffix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  description = "Subnet delegated to Microsoft.App/environments, in the same region as location. null = Azure-managed network (no VNet injection)."
  type        = string
  default     = null
}

variable "log_analytics_id" {
  type = string
}

variable "identity_id" {
  type = string
}

variable "acr_login_server" {
  type = string
}

variable "image" {
  description = "Container image. Replace with <acr>.azurecr.io/<repo>:<tag> after pushing your own."
  type        = string
  default     = "mcr.microsoft.com/k8se/quickstart:latest"
}

variable "app_insights_connection_string" {
  type      = string
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
