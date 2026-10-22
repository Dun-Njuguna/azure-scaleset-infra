output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "app_subnet_id" {
  # Servers need internet on first boot (packages, image pull), so anything
  # placed in this subnet waits until the NAT gateway is attached.
  value      = azurerm_subnet.app.id
  depends_on = [azurerm_subnet_nat_gateway_association.app]
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

output "bastion_subnet_id" {
  value = var.bastion_enabled ? azurerm_subnet.bastion[0].id : null
  # Bastion must not be created until its NSG is attached, or Azure rejects it.
  depends_on = [azurerm_subnet_network_security_group_association.bastion]
}

output "nat_public_ip" {
  value = azurerm_public_ip.nat.ip_address
}

output "subnet_prefixes" {
  value = local.subnets
}
