variable "name_suffix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "daily_quota_gb" {
  type    = number
  default = 1
}

variable "tags" {
  type    = map(string)
  default = {}
}
