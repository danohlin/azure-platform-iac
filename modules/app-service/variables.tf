variable "name" {
  description = "Globally unique; becomes <name>.azurewebsites.net."
  type        = string
}

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
  description = "Subnet delegated to Microsoft.Web/serverFarms."
  type        = string
}

variable "identity_id" {
  type = string
}

variable "identity_client_id" {
  type = string
}

variable "app_insights_connection_string" {
  type      = string
  sensitive = true
}

variable "greeting_secret_id" {
  type = string
}

variable "sql_server_fqdn" {
  type = string
}

variable "sql_database_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
