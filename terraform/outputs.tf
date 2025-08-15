output "resource_group_name" {
  value = local.rg_name
}

output "vnet_id" {
  value = module.network.vnet_id
}

output "subnet_ids" {
  value = module.network.subnet_ids
}

output "app_gateway_public_ip" {
  value = module.app_gateway.public_ip_address
}

output "app_gateway_frontend_url" {
  value = "http://${module.app_gateway.public_ip_address}"
  description = "Frontend URL (HTTP). For production, add HTTPS listener/cert."
}

output "web_app_default_hostname" {
  value = module.web_app.default_hostname
}

output "sql_server_fqdn" {
  value = module.sql.server_fqdn
}