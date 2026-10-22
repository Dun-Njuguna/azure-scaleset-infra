output "id" {
  value = azurerm_key_vault.this.id
}

output "name" {
  value = azurerm_key_vault.this.name
}

output "breakglass_secret_name" {
  value = azurerm_key_vault_secret.breakglass_ssh_key.name
}
