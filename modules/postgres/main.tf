resource "azurerm_postgresql_flexible_server" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  version             = var.postgres_version
  sku_name            = var.sku_name
  storage_mb          = var.storage_mb
  auto_grow_enabled   = true # a full disk is an outage; growing is not

  # Private access only: VNet-injected, no public endpoint at all.
  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  public_network_access_enabled = false

  administrator_login = var.administrator_login
  # Write-only: never written to state or shown in plans.
  administrator_password_wo         = var.administrator_password
  administrator_password_wo_version = var.administrator_password_version

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  zone = var.high_availability_enabled ? "1" : null

  dynamic "high_availability" {
    for_each = var.high_availability_enabled ? [1] : []
    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = "2"
    }
  }

  maintenance_window {
    day_of_week  = 0 # Sunday
    start_hour   = 2
    start_minute = 0
  }

  tags = var.tags

  lifecycle {
    # After a failover Azure swaps primary and standby zones. Don't fight it.
    ignore_changes = [zone, high_availability[0].standby_availability_zone]
  }
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  for_each = toset(var.databases)

  name      = each.value
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"

  lifecycle {
    prevent_destroy = false
  }
}
