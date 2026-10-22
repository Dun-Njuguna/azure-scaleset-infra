output "id" {
  value = azurerm_managed_redis.this.id
}

output "hostname" {
  value = azurerm_managed_redis.this.hostname
}

output "port" {
  value = azurerm_managed_redis.this.default_database[0].port
}

output "primary_access_key" {
  value     = azurerm_managed_redis.this.default_database[0].primary_access_key
  sensitive = true
}
