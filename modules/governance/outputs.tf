output "budget_id" {
  value = azurerm_consumption_budget_resource_group.this.id
}

output "lock_enabled" {
  value = length(azurerm_management_lock.rg) > 0
}
