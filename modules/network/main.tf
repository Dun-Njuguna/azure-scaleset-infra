locals {
  # Address plan for a /16, e.g. 10.10.0.0/16:
  #   10.10.1.0/24  snet-app            VMSS instances
  #   10.10.2.0/24  snet-db             Postgres (delegated)
  #   10.10.3.0/24  snet-pe             private endpoints (Redis)
  #   10.10.4.0/26  AzureBastionSubnet  Azure Bastion (/26 is the minimum)
  subnets = {
    app     = cidrsubnet(var.address_space, 8, 1)
    db      = cidrsubnet(var.address_space, 8, 2)
    pe      = cidrsubnet(var.address_space, 8, 3)
    bastion = cidrsubnet(var.address_space, 10, 16)
  }
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnets.app]

  # Outbound goes through the NAT gateway (nat.tf), not Azure's implicit
  # default outbound access (retired for new subnets).
  default_outbound_access_enabled = false

  # Lets instances reach Key Vault while the vault's firewall stays closed.
  service_endpoint {
    service = "Microsoft.KeyVault"
  }
}

resource "azurerm_subnet" "db" {
  name                            = "snet-db"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [local.subnets.db]
  default_outbound_access_enabled = false

  delegation {
    name = "postgres-flexible"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "pe" {
  name                            = "snet-pe"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [local.subnets.pe]
  default_outbound_access_enabled = false

  # Make NSG rules apply to private endpoints in this subnet.
  private_endpoint_network_policies = "Enabled"
}

# Azure requires this exact name for Bastion.
resource "azurerm_subnet" "bastion" {
  count = var.bastion_enabled ? 1 : 0

  name                            = "AzureBastionSubnet"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [local.subnets.bastion]
  default_outbound_access_enabled = false
}
