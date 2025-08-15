variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "name_prefix" {
  type = string
}
variable "vnet_id" {
  type = string
}

variable "enable_webapp_zone" {
  type    = bool
  default = true
}

variable "enable_sql_zone" {
  type    = bool
  default = true
}