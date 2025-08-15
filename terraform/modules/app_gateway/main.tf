resource "azurerm_public_ip" "pip" {
  name                = "${var.name_prefix}-agw-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "agw" {
  name                = "${var.name_prefix}-agw"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  waf_configuration {
    enabled                  = true
    firewall_mode            = "Prevention"
    rule_set_type            = "OWASP"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    max_request_body_size_kb = 128
  }

  gateway_ip_configuration {
    name      = "gwipc"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = "feip"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  frontend_port {
    name = "feport-80"
    port = 80
  }

  backend_address_pool {
    name  = "be-pool"
    fqdns = [var.backend_fqdn]
  }

  backend_http_settings {
    name                                = "be-https"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = "listener-80"
    frontend_ip_configuration_name = "feip"
    frontend_port_name             = "feport-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule-80"
    rule_type                  = "Basic"
    http_listener_name         = "listener-80"
    backend_address_pool_name  = "be-pool"
    backend_http_settings_name = "be-https"
  }

  probe {
    name                = "probe-https"
    protocol            = "Https"
    host                = var.backend_fqdn
    path                = "/"
    pick_host_name_from_backend_http_settings = true
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }
}