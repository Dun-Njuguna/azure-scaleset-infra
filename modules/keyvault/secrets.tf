resource "azurerm_key_vault_secret" "breakglass_ssh_key" {
  name         = "breakglass-ssh-private-key"
  key_vault_id = azurerm_key_vault.this.id
  value        = var.breakglass_private_key
  content_type = "text/plain; ssh-private-key"
  depends_on   = [time_sleep.rbac_propagation]
}

# Write-only: the value goes to Key Vault but never into Terraform state or plans.
resource "azurerm_key_vault_secret" "postgres_password" {
  name             = "postgres-password"
  key_vault_id     = azurerm_key_vault.this.id
  value_wo         = var.postgres_password
  value_wo_version = var.postgres_password_version
  content_type     = "text/plain"
  depends_on       = [time_sleep.rbac_propagation]
}

resource "azurerm_key_vault_secret" "redis_access_key" {
  count = var.redis_enabled ? 1 : 0

  name         = "redis-access-key"
  key_vault_id = azurerm_key_vault.this.id
  value        = var.redis_access_key
  content_type = "text/plain"
  depends_on   = [time_sleep.rbac_propagation]
}
