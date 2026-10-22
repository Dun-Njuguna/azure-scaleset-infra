# ---------------------------------------------------------------------------
# Outbound internet for the app servers (apt, image pulls, Key Vault).
# The subnet has default outbound access turned off, so this NAT gateway is
# the ONLY way out. Benefits over load balancer outbound rules:
#   - one fixed public IP for all egress (easy to allow-list elsewhere)
#   - ~64k SNAT ports per IP, allocated on demand (no port exhaustion
#     as the scale set grows)
#   - egress no longer depends on load balancer configuration
# NAT gateway is outbound-only: nothing can connect in through it.
# ---------------------------------------------------------------------------
resource "azurerm_public_ip" "nat" {
  name                = "pip-${var.name_prefix}-nat"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "this" {
  name                    = "ng-${var.name_prefix}"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "app" {
  subnet_id      = azurerm_subnet.app.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}
