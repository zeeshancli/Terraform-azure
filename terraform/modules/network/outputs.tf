output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnet_ids" {
  value = {
    appgw             = azurerm_subnet.appgw.id
    private_endpoints = azurerm_subnet.pe.id
    app               = azurerm_subnet.app.id
    data              = azurerm_subnet.data.id
  }
}