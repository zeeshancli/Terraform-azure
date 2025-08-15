resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name_prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
}

# NSG for private endpoints subnet (note: NSG rules don't apply to Private Endpoint NICs)
resource "azurerm_network_security_group" "pe" {
  name                = "${var.name_prefix}-nsg-pe"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowVNetInBound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "DenyInternetInBound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "pe" {
  name                          = "${var.name_prefix}-snet-pe"
  resource_group_name           = var.resource_group_name
  virtual_network_name          = azurerm_virtual_network.vnet.name
  address_prefixes              = var.subnet_prefixes.private_endpoints
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_subnet_network_security_group_association" "pe" {
  subnet_id                 = azurerm_subnet.pe.id
  network_security_group_id = azurerm_network_security_group.pe.id
}

# App Gateway subnet (avoid attaching an NSG to AppGW subnet to prevent blocking required traffic)
resource "azurerm_subnet" "appgw" {
  name                 = "${var.name_prefix}-snet-appgw"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_prefixes.appgw
  service_endpoints    = concat(
    var.enable_service_endpoints_webapp ? ["Microsoft.Web"] : [],
    var.enable_service_endpoints_sql ? ["Microsoft.Sql"] : []
  )
}

# App subnet (for future workloads, and to host service endpoint rules for inbound restrictions to Web App)
resource "azurerm_network_security_group" "app" {
  name                = "${var.name_prefix}-nsg-app"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowFromAppGw443"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = azurerm_subnet.appgw.address_prefixes[0]
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "app" {
  name                 = "${var.name_prefix}-snet-app"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_prefixes.app
  service_endpoints    = concat(
    var.enable_service_endpoints_webapp ? ["Microsoft.Web"] : [],
    var.enable_service_endpoints_sql ? ["Microsoft.Sql"] : []
  )
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# Data subnet (optional usage)
resource "azurerm_network_security_group" "data" {
  name                = "${var.name_prefix}-nsg-data"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowAppToSql1433"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = azurerm_subnet.app.address_prefixes[0]
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "data" {
  name                 = "${var.name_prefix}-snet-data"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_prefixes.data
  service_endpoints    = var.enable_service_endpoints_sql ? ["Microsoft.Sql"] : []
}

resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data.id
}