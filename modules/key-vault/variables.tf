variable "name" {
  description = "Globally unique, 3-24 chars."
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

variable "deployer_object_id" {
  description = "Object ID of whoever runs Terraform."
  type        = string
}

variable "workload_principal_id" {
  description = "Principal ID of the managed identity used by the apps."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
