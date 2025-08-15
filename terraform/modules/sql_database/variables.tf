variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "name_prefix" {
  type = string
}

variable "admin_login" {
  type = string
}
variable "admin_password" {
  type      = string
  sensitive = true
}
variable "sku_name" {
  type = string
}

variable "network_mode" {
  description = "'private_endpoint' or 'service_endpoint'"
  type        = string
}

variable "private_endpoints_subnet_id" {
  type = string
}

variable "sql_privatelink_dns_zone_id" {
  type    = string
  default = null
}

variable "service_endpoint_allowed_subnet_ids" {
  description = "Subnet IDs allowed via SQL VNet rules when using service endpoints."
  type        = list(string)
  default     = []
}