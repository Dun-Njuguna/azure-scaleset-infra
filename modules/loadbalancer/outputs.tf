output "id" {
  value = azurerm_lb.this.id
}

output "name" {
  value = azurerm_lb.this.name
}

output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.app.id
}

output "public_ip" {
  value = azurerm_public_ip.this.ip_address
}

output "fqdn" {
  value = azurerm_public_ip.this.fqdn
}

output "ssh_port_range" {
  value = var.ssh_enabled ? "${var.ssh_frontend_port_start}-${var.ssh_frontend_port_start + var.max_instances - 1}" : null
}
