variable "name_suffix" {
  description = "Appended to resource names, e.g. azplat-dev."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "address_space" {
  description = "VNet CIDR. Must be a /16 for the subnet math in main.tf."
  type        = string
  default     = "10.20.0.0/16"
}

variable "tags" {
  type    = map(string)
  default = {}
}
