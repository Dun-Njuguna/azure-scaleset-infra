# Composes the modules. Everything that differs between environments comes
# from envs/<env>.tfvars; nothing here mentions dev, staging or prod.

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.tags
}

# =============================================================================
# Foundations
# =============================================================================
module "network" {
  source = "./modules/network"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.address_space
  admin_cidrs         = var.admin_cidrs
  ssh_enabled         = var.ssh_enabled
  tags                = local.tags
}

module "governance" {
  source = "./modules/governance"

  name_prefix         = local.name_prefix
  resource_group_id   = azurerm_resource_group.this.id
  budget_amount       = var.budget_amount
  budget_alert_emails = var.alert_emails
  lock_enabled        = var.lock_enabled
}

# =============================================================================
# Secrets
# =============================================================================

# Break-glass admin key. The private half only exists in Key Vault (and state).
resource "tls_private_key" "breakglass" {
  algorithm = "ED25519"
}

# Ephemeral: generated during apply, handed to Postgres and Key Vault as
# write-only values, and never saved in state or plan files.
ephemeral "random_password" "postgres" {
  length      = 32
  special     = false # avoids URL/escaping problems in connection strings
  min_upper   = 4
  min_lower   = 4
  min_numeric = 4
}

module "keyvault" {
  source = "./modules/keyvault"

  name                     = "kv-${local.name_prefix}-${local.unique}"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.this.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled = var.key_vault_purge_protection
  admin_cidrs              = var.admin_cidrs
  allowed_subnet_ids       = [module.network.app_subnet_id]
  deployer_object_id       = data.azurerm_client_config.current.object_id

  breakglass_private_key    = tls_private_key.breakglass.private_key_openssh
  postgres_password         = ephemeral.random_password.postgres.result
  postgres_password_version = var.postgres_password_version
  redis_enabled             = var.redis.enabled
  redis_access_key          = var.redis.enabled ? module.redis[0].primary_access_key : null

  tags = local.tags
}

# =============================================================================
# Data
# =============================================================================
module "postgres" {
  source = "./modules/postgres"

  name                = "psql-${local.name_prefix}-${local.unique}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  delegated_subnet_id = module.network.db_subnet_id
  private_dns_zone_id = module.network.postgres_dns_zone_id

  sku_name                     = var.postgres.sku_name
  storage_mb                   = var.postgres.storage_mb
  backup_retention_days        = var.postgres.backup_retention_days
  geo_redundant_backup_enabled = var.postgres.geo_redundant_backup_enabled
  high_availability_enabled    = var.postgres.high_availability_enabled

  administrator_password         = ephemeral.random_password.postgres.result
  administrator_password_version = var.postgres_password_version

  tags = local.tags
}

module "redis" {
  source = "./modules/redis"
  count  = var.redis.enabled ? 1 : 0

  name                      = "redis-${local.name_prefix}-${local.unique}"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.this.name
  sku_name                  = var.redis.sku_name
  high_availability_enabled = var.redis.high_availability_enabled
  subnet_id                 = module.network.pe_subnet_id
  private_dns_zone_id       = module.network.redis_dns_zone_id
  tags                      = local.tags
}

# =============================================================================
# Compute
# =============================================================================
module "users" {
  source = "./modules/users"

  environment = var.environment
  users       = var.users
}

module "loadbalancer" {
  source = "./modules/loadbalancer"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  dns_label           = "${local.name_prefix}-${local.unique}"
  ssh_enabled         = var.ssh_enabled
  max_instances       = var.instances.max
  tags                = local.tags
}

module "compute" {
  source = "./modules/compute-vmss"

  name_prefix         = local.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.network.app_subnet_id
  backend_pool_id     = module.loadbalancer.backend_pool_id
  zones               = var.zones

  vm_size           = var.vm_size
  instances_min     = var.instances.min
  instances_max     = var.instances.max
  instances_default = var.instances.default

  admin_username   = local.admin_username
  admin_public_key = tls_private_key.breakglass.public_key_openssh
  cloud_init_users = module.users.cloud_init_users

  app_image         = var.app_image
  key_vault_id      = module.keyvault.id
  key_vault_name    = module.keyvault.name
  postgres_host     = module.postgres.fqdn
  postgres_user     = module.postgres.administrator_login
  postgres_database = "app"
  redis_enabled     = var.redis.enabled
  redis_host        = var.redis.enabled ? module.redis[0].hostname : null

  autoscale_schedule_enabled = var.autoscale_schedule_enabled
  alert_emails               = var.alert_emails
  tags                       = local.tags
}

# =============================================================================
# Monitoring
# =============================================================================
module "monitoring" {
  source = "./modules/monitoring"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  alert_emails        = var.alert_emails
  vmss_id             = module.compute.id
  lb_id               = module.loadbalancer.id
  postgres_id         = module.postgres.id
  tags                = local.tags
}
