variable "name" {
  description = "Globally unique server name."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "entra_admin_login" {
  description = "Display name / UPN of the Entra ID SQL admin."
  type        = string
}

variable "entra_admin_object_id" {
  description = "Object ID of the Entra ID SQL admin."
  type        = string
}

variable "app_subnet_id" {
  description = "Subnet (with Microsoft.Sql service endpoint) allowed to connect."
  type        = string
}

variable "client_ip" {
  description = "Your public IP to allow through the firewall, or null."
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "Vault where the generated admin password is stored."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
