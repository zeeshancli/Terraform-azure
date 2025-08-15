locals {
  # Short codes for regions (extend as needed)
  location_short = lookup({
    eastus        = "eus"
    eastus2       = "eus2"
    westus        = "wus"
    westus2       = "wus2"
    westus3       = "wus3"
    centralus     = "cus"
    northeurope   = "neu"
    westeurope    = "weu"
    uksouth       = "uks"
    ukwest        = "ukw"
    southeastasia = "sea"
  }, lower(var.location), lower(var.location))

  name_prefix = "${var.org_prefix}-${var.environment}-${local.location_short}"

  create_rg = var.resource_group_name == ""

  rg_name = local.create_rg ? "${local.name_prefix}-rg" : var.resource_group_name

  # Enable Service Endpoints on subnets based on mode toggles
  se_webapp_enabled = var.webapp_network_mode == "service_endpoint"
  se_sql_enabled    = var.sql_network_mode == "service_endpoint"

  # Default tags to apply across resources (use: tags = merge(local.default_tags, { ... }))
  default_tags = {
    environment = var.environment
    org         = var.org_prefix
  }
}