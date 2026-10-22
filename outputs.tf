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

output "ssh" {
  description = "How to reach an instance. Each instance has its own port in the range."
  value = var.ssh_enabled ? {
    host       = module.loadbalancer.fqdn
    port_range = module.loadbalancer.ssh_port_range
    example    = "ssh -p ${split("-", module.loadbalancer.ssh_port_range)[0]} <your-username>@${module.loadbalancer.fqdn}"
    port_map   = "Portal: ${module.loadbalancer.name} -> Inbound NAT rules -> ssh"
  } : null
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
