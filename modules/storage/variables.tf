variable "name" {
  description = "Globally unique, 3-24 lowercase letters and digits."
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
