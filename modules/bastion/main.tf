locals {
  # Native client (az CLI) and connect-by-IP need Standard or Premium.
  advanced = contains(["Standard", "Premium"], var.sku)
}

resource "azurerm_public_ip" "bastion" {
  name                = "pip-${var.name_prefix}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "this" {
  name                = "bas-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku

  # Lets you SSH from your own terminal: az network bastion ssh ...
  tunneling_enabled = local.advanced
  # Connect by private IP, which is how you reach scale set instances.
  ip_connect_enabled = local.advanced

  copy_paste_enabled = true
  file_copy_enabled  = false # keep data from walking out through the browser

  ip_configuration {
    name                 = "bastion"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = var.tags
}
