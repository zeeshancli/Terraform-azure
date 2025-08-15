resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_mssql_server" "server" {
  name                         = "${var.name_prefix}-sql-${random_string.suffix.result}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.admin_login
  administrator_login_password = var.admin_password

  public_network_access_enabled = var.network_mode == "private_endpoint" ? false : true
  minimum_tls_version           = "1.2"
}

resource "azurerm_mssql_database" "db" {
  name           = "${var.name_prefix}-sqldb"
  server_id      = azurerm_mssql_server.server.id
  sku_name       = var.sku_name
  zone_redundant = false
}

# VNet rules for service endpoint model
resource "azurerm_mssql_virtual_network_rule" "se_rules" {
  for_each = var.network_mode == "service_endpoint" ? toset(var.service_endpoint_allowed_subnet_ids) : []
  name      = "${var.name_prefix}-sql-vnetrule-${replace(each.value, "/","-")}"
  server_id = azurerm_mssql_server.server.id
  subnet_id = each.value
}

# Private Endpoint for SQL
resource "azurerm_private_endpoint" "sql_pe" {
  count               = var.network_mode == "private_endpoint" ? 1 : 0
  name                = "${var.name_prefix}-pe-sql"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id

  private_service_connection {
    name                           = "${var.name_prefix}-psc-sql"
    private_connection_resource_id = azurerm_mssql_server.server.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.sql_privatelink_dns_zone_id != null ? [1] : []
    content {
      name                 = "sql-zone-group"
      private_dns_zone_ids = [var.sql_privatelink_dns_zone_id]
    }
  }
}