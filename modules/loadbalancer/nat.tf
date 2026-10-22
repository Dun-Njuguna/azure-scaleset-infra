# One NAT rule covering the whole pool: instance N gets frontend port
# ssh_frontend_port_start + N. List mappings with:
#   az network lb inbound-nat-rule show-backend-port-mapping ...
# (scripts/whoami-on-instances.sh does this for you)
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
