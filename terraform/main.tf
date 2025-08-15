# Remote state backend (per-environment via -backend-config files, e.g. envs/dev.backend.hcl)
terraform {
  backend "azurerm" {}
}


# Resource Group (created if not supplied)
resource "azurerm_resource_group" "rg" {
  count    = local.create_rg ? 1 : 0
  name     = local.rg_name
  location = var.location
}

module "network" {
  source = "./modules/network"

  resource_group_name = local.rg_name
  location            = var.location
  name_prefix         = local.name_prefix

  address_space = var.address_space

  subnet_prefixes = {
    appgw             = var.subnet_prefixes.appgw
    private_endpoints = var.subnet_prefixes.private_endpoints
    app               = var.subnet_prefixes.app
    data              = var.subnet_prefixes.data
  }

  # Enable service endpoints when modes require them
  enable_service_endpoints_webapp = local.se_webapp_enabled
  enable_service_endpoints_sql    = local.se_sql_enabled
}

module "dns" {
  source = "./modules/dns"

  resource_group_name = local.rg_name
  location            = var.location
  name_prefix         = local.name_prefix
  vnet_id             = module.network.vnet_id

  enable_webapp_zone = var.dns_enable_webapp_zone
  enable_sql_zone    = var.dns_enable_sql_zone
}

module "web_app" {
  source = "./modules/web_app"

  resource_group_name = local.rg_name
  location            = var.location
  name_prefix         = local.name_prefix

  plan_sku   = var.webapp_sku
  app_kind   = var.webapp_stack.kind
  linux_fx   = var.webapp_stack.linux_fx
  app_settings = var.webapp_settings

  network_mode                = var.webapp_network_mode
  appgw_subnet_id            = module.network.subnet_ids.appgw
  private_endpoints_subnet_id = module.network.subnet_ids.private_endpoints

  # DNS zone for private endpoint
  webapp_privatelink_dns_zone_id = module.dns.webapp_zone_id

  # Explicit dependency to ensure DNS zone + VNet link exist before PE resolves
  depends_on = [module.dns]
}

module "sql" {
  source = "./modules/sql_database"

  resource_group_name = local.rg_name
  location            = var.location
  name_prefix         = local.name_prefix

  admin_login    = var.sql_admin_login
  admin_password = var.sql_admin_password
  sku_name       = var.sql_sku

  network_mode                 = var.sql_network_mode
  private_endpoints_subnet_id  = module.network.subnet_ids.private_endpoints
  service_endpoint_allowed_subnet_ids = [
    module.network.subnet_ids.appgw,
    module.network.subnet_ids.app
  ]

  sql_privatelink_dns_zone_id = module.dns.sql_zone_id

  depends_on = [module.dns]
}

module "app_gateway" {
  source = "./modules/app_gateway"

  resource_group_name = local.rg_name
  location            = var.location
  name_prefix         = local.name_prefix

  subnet_id    = module.network.subnet_ids.appgw
  backend_fqdn = module.web_app.default_hostname

  # Make sure DNS link exists so backend FQDN resolves to private IP when PE mode is used
  depends_on = [module.dns, module.web_app]
}