# ---------------------------------------------------------------------------
# App subnet: HTTP from anywhere, SSH only from admin ranges (if enabled).
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "app" {
  name                = "nsg-${var.name_prefix}-app"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = local.subnets.app
    destination_port_range     = "80"
  }

  dynamic "security_rule" {
    for_each = var.ssh_enabled ? [1] : []
    content {
      name                       = "allow-ssh-admins"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefixes    = var.admin_cidrs
      source_port_range          = "*"
      destination_address_prefix = local.subnets.app
      destination_port_range     = "22"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# ---------------------------------------------------------------------------
# Data subnets: only the app subnet may connect.
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "db" {
  name                = "nsg-${var.name_prefix}-db"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-postgres-from-app"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.subnets.app
    source_port_range          = "*"
    destination_address_prefix = local.subnets.db
    destination_port_range     = "5432"
  }

  security_rule {
    name                       = "deny-other-vnet-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db.id
}

resource "azurerm_network_security_group" "pe" {
  name                = "nsg-${var.name_prefix}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-redis-from-app"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.subnets.app
    source_port_range          = "*"
    destination_address_prefix = local.subnets.pe
    destination_port_range     = "10000" # Azure Managed Redis TLS port
  }

  security_rule {
    name                       = "deny-other-vnet-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "pe" {
  subnet_id                 = azurerm_subnet.pe.id
  network_security_group_id = azurerm_network_security_group.pe.id
}
