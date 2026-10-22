# Stops anyone (including a mistaken 'terraform destroy') deleting the
# environment. Removing it is a deliberate two-step action:
#   1. set lock_enabled = false and apply
#   2. destroy
resource "azurerm_management_lock" "rg" {
  count = var.lock_enabled ? 1 : 0

  name       = "lock-${var.name_prefix}"
  scope      = var.resource_group_id
  lock_level = "CanNotDelete"
  notes      = "Managed by Terraform. Set lock_enabled = false and apply before destroying."
}
