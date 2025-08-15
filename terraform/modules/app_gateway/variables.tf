variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "name_prefix" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "backend_fqdn" {
  description = "Backend FQDN (Web App default hostname). Resolves to private IP when PE is used."
  type        = string
}