variable "name" {
  description = "Globally unique, 5-50 alphanumerics."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "deployer_object_id" {
  type = string
}

variable "workload_principal_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
