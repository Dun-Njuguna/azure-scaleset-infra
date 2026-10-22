resource "azurerm_key_vault" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = true # Azure RBAC, not legacy access policies
  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = 7

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    # Key Vault stores single IPs without "/32", so strip it to avoid a
    # permanent diff on every plan.
    ip_rules                   = [for c in var.admin_cidrs : trimsuffix(c, "/32") if !strcontains(c, ":")]
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = var.tags
}
