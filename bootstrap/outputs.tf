output "storage_account_name" {
  value = azurerm_storage_account.state.name
}

output "backend_config" {
  description = "Paste into envs/<env>.backend.hcl (change the key per environment)."
  value       = <<-EOT
    resource_group_name  = "${azurerm_resource_group.state.name}"
    storage_account_name = "${azurerm_storage_account.state.name}"
    container_name       = "${azurerm_storage_container.state.name}"
    key                  = "<env>.tfstate"
    use_azuread_auth     = true
  EOT
}
