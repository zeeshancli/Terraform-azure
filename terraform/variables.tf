variable "org_prefix" {
  description = "Organization or project prefix for naming."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)."
  type        = string
}

variable "location" {
  description = "Azure region (e.g., eastus)."
  type        = string
}

variable "address_space" {
  description = "Virtual network CIDR."
  type        = list(string)
}

variable "subnet_prefixes" {
  description = "CIDRs for key subnets."
  type = object({
    appgw            = list(string)
    private_endpoints = list(string)
    app              = list(string)
    data             = list(string)
  })
}

variable "webapp_network_mode" {
  description = "How the Web App is exposed: 'private_endpoint' or 'service_endpoint'."
  type        = string
  validation {
    condition     = contains(["private_endpoint", "service_endpoint"], var.webapp_network_mode)
    error_message = "webapp_network_mode must be 'private_endpoint' or 'service_endpoint'."
  }
}

variable "sql_network_mode" {
  description = "How SQL is exposed: 'private_endpoint' or 'service_endpoint'."
  type        = string
  validation {
    condition     = contains(["private_endpoint", "service_endpoint"], var.sql_network_mode)
    error_message = "sql_network_mode must be 'private_endpoint' or 'service_endpoint'."
  }
}

variable "webapp_settings" {
  description = "App settings (key/value) for the Web App."
  type        = map(string)
  default     = {}
}

variable "webapp_sku" {
  description = "App Service Plan SKU (e.g., B1, P1v3)."
  type        = string
  default     = "P1v3"
}

variable "webapp_stack" {
  description = "Web App runtime stack."
  type = object({
    kind          = string # "linux"
    linux_fx      = string # e.g., "DOTNET|8.0", "NODE|18-lts"
  })
  default = {
    kind     = "linux"
    linux_fx = "DOTNET|8.0"
  }
}

variable "sql_admin_login" {
  description = "SQL admin login."
  type        = string
}

variable "sql_admin_password" {
  description = "SQL admin password."
  type        = string
  sensitive   = true
}

variable "sql_sku" {
  description = "SQL DB SKU (e.g., S0, GP_S_Gen5_2)."
  type        = string
  default     = "S0"
}

variable "dns_enable_webapp_zone" {
  description = "Create/link Private DNS zone for Web App private endpoints."
  type        = bool
  default     = true
}

variable "dns_enable_sql_zone" {
  description = "Create/link Private DNS zone for SQL private endpoints."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Name of the Resource Group. If empty, one will be created."
  type        = string
  default     = ""
}