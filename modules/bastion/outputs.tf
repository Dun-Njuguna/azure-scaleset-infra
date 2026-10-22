output "name" {
  value = azurerm_bastion_host.this.name
}

output "id" {
  value = azurerm_bastion_host.this.id
}

output "native_client_enabled" {
  value = local.advanced
}
