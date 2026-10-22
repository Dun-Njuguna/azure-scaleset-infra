# One NAT rule (v2) covering the whole backend pool: Azure gives each instance
# its own frontend port from the range. See which instance has which port in
# the portal: Load balancer -> Inbound NAT rules -> ssh.
resource "azurerm_lb_nat_rule" "ssh" {
  count = var.ssh_enabled ? 1 : 0

  name                           = "ssh"
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_ip_configuration_name = "public"
  frontend_port_start            = var.ssh_frontend_port_start
  frontend_port_end              = var.ssh_frontend_port_start + var.max_instances - 1
  backend_port                   = 22
  backend_address_pool_id        = azurerm_lb_backend_address_pool.app.id
  idle_timeout_in_minutes        = 30
}
