# Whoever runs Terraform may manage secrets (data plane, via RBAC).
resource "azurerm_role_assignment" "deployer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.deployer_object_id
}

# RBAC changes take a little while to reach Key Vault's data plane.
# Without this wait, the first apply fails with 403 on the secrets below.
resource "time_sleep" "rbac_propagation" {
  create_duration = "60s"
  depends_on      = [azurerm_role_assignment.deployer]
}
