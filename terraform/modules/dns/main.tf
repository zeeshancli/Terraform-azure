# Private DNS zone for Web App Private Endpoint
resource "azurerm_private_dns_zone" "webapp" {
  count               = var.enable_webapp_zone ? 1 : 0
  name                = "privatelink.azurewebsites.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "webapp" {
  count                 = var.enable_webapp_zone ? 1 : 0
  name                  = "${var.name_prefix}-pdnslink-webapp"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.webapp[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

# Private DNS zone for SQL Private Endpoint
resource "azurerm_private_dns_zone" "sql" {
  count               = var.enable_sql_zone ? 1 : 0
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  count                 = var.enable_sql_zone ? 1 : 0
  name                  = "${var.name_prefix}-pdnslink-sql"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}