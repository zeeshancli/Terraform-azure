resource "azurerm_service_plan" "plan" {
  name                = "${var.name_prefix}-asp"
  location            = var.location
  resource_group_name = var.resource_group_name

  os_type  = "Linux"
  sku_name = var.plan_sku
}

resource "azurerm_linux_web_app" "app" {
  name                = "${var.name_prefix}-web"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.plan.id

  https_only = true

  site_config {
    ftps_state = "Disabled"

    # Map linux_fx (e.g., DOTNET|8.0 or NODE|18-lts) to the appropriate application_stack field
    application_stack {
      dotnet_version = upper(split("|", var.linux_fx)[0]) == "DOTNET" ? split("|", var.linux_fx)[1] : null
      node_version   = upper(split("|", var.linux_fx)[0]) == "NODE"   ? split("|", var.linux_fx)[1] : null
    }
  }

  public_network_access_enabled = var.network_mode == "private_endpoint" ? false : true

  app_settings = var.app_settings

  dynamic "ip_restriction" {
    for_each = var.network_mode == "service_endpoint" ? [1] : []
    content {
      name                      = "allow-appgw-subnet"
      action                    = "Allow"
      priority                  = 100
      virtual_network_subnet_id = var.appgw_subnet_id
    }
  }

  dynamic "scm_ip_restriction" {
    for_each = var.network_mode == "service_endpoint" ? [1] : []
    content {
      name                      = "allow-appgw-subnet-scm"
      action                    = "Allow"
      priority                  = 100
      virtual_network_subnet_id = var.appgw_subnet_id
    }
  }

  # Default deny when using service endpoint access restrictions
  dynamic "ip_restriction" {
    for_each = var.network_mode == "service_endpoint" ? [1] : []
    content {
      name     = "deny-all"
      action   = "Deny"
      priority = 65000
      ip_address = "0.0.0.0/0"
    }
  }

  dynamic "scm_ip_restriction" {
    for_each = var.network_mode == "service_endpoint" ? [1] : []
    content {
      name     = "deny-all-scm"
      action   = "Deny"
      priority = 65000
      ip_address = "0.0.0.0/0"
    }
  }
}

# Private Endpoint for Web App when required
resource "azurerm_private_endpoint" "webapp_pe" {
  count               = var.network_mode == "private_endpoint" ? 1 : 0
  name                = "${var.name_prefix}-pe-web"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id

  private_service_connection {
    name                           = "${var.name_prefix}-psc-web"
    private_connection_resource_id = azurerm_linux_web_app.app.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.webapp_privatelink_dns_zone_id != null ? [1] : []
    content {
      name                 = "webapp-zone-group"
      private_dns_zone_ids = [var.webapp_privatelink_dns_zone_id]
    }
  }
}