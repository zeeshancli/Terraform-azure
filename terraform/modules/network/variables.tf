variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "name_prefix" {
  type = string
}

variable "address_space" {
  type = list(string)
}

variable "subnet_prefixes" {
  type = object({
    appgw             = list(string)
    private_endpoints = list(string)
    app               = list(string)
    data              = list(string)
  })
}

variable "enable_service_endpoints_webapp" {
  type        = bool
  description = "Enable Microsoft.Web service endpoints on AppGW/App subnets when webapp is in service_endpoint mode."
  default     = false
}

variable "enable_service_endpoints_sql" {
  type        = bool
  description = "Enable Microsoft.Sql service endpoints on app/data subnets when SQL is in service_endpoint mode."
  default     = false
}