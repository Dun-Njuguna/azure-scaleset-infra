output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "app_subnet_id" {
  value = azurerm_subnet.app.id
}

output "db_subnet_id" {
  value = azurerm_subnet.db.id
}

output "pe_subnet_id" {
  value = azurerm_subnet.pe.id
}

output "postgres_dns_zone_id" {
  # Postgres must wait for the VNet link, or private access setup fails.
  value      = azurerm_private_dns_zone.postgres.id
  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

output "redis_dns_zone_id" {
  value      = azurerm_private_dns_zone.redis.id
  depends_on = [azurerm_private_dns_zone_virtual_network_link.redis]
}
