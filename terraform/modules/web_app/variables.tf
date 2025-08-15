variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "name_prefix" {
  type = string
}

variable "plan_sku" {
  type = string
}

variable "app_kind" {
  type = string # "linux"
}

variable "linux_fx" {
  type = string
}

variable "app_settings" {
  type    = map(string)
  default = {}
}

variable "network_mode" {
  description = "'private_endpoint' or 'service_endpoint'"
  type        = string
}

variable "appgw_subnet_id" {
  description = "Subnet ID used for App Gateway; used for service endpoint-based access restriction."
  type        = string
}

variable "private_endpoints_subnet_id" {
  description = "Subnet ID where Private Endpoints are created."
  type        = string
}

variable "webapp_privatelink_dns_zone_id" {
  description = "Private DNS zone ID for privatelink.azurewebsites.net (optional)."
  type        = string
  default     = null
}