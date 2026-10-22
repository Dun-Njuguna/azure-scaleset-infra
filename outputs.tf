output "environment" {
  value = var.environment
}

output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "app_url" {
  value = "http://${module.loadbalancer.fqdn}"
}

output "vmss_name" {
  value = module.compute.name
}

output "load_balancer_name" {
  value = module.loadbalancer.name
}

output "users" {
  description = "Linux users on every instance in this environment (username => sudo)."
  value       = module.users.summary
}

output "bastion" {
  description = "How to SSH in. There is no other route to the servers."
  value = var.bastion.enabled ? {
    name          = module.bastion[0].name
    native_client = module.bastion[0].native_client_enabled
    connect       = "./scripts/ssh.sh ${var.environment}"
  } : null
}

output "subnets" {
  value = module.network.subnet_prefixes
}

output "key_vault_name" {
  value = module.keyvault.name
}

output "breakglass_key_command" {
  description = "Emergency only: fetch the break-glass admin key."
  value       = "az keyvault secret show --vault-name ${module.keyvault.name} --name ${module.keyvault.breakglass_secret_name} --query value -o tsv > breakglass && chmod 600 breakglass"
}

output "postgres_fqdn" {
  value = module.postgres.fqdn
}

output "postgres_server_name" {
  value = module.postgres.name
}

output "redis_hostname" {
  value = var.redis.enabled ? module.redis[0].hostname : null
}
