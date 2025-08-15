output "webapp_zone_id" {
  value       = try(azurerm_private_dns_zone.webapp[0].id, null)
  description = "ID of privatelink.azurewebsites.net zone (if created)."
}

output "sql_zone_id" {
  value       = try(azurerm_private_dns_zone.sql[0].id, null)
  description = "ID of privatelink.database.windows.net zone (if created)."
}