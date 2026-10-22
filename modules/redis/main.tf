# Azure Managed Redis: the successor to Azure Cache for Redis, which is
# closed to new customers and retiring.
resource "azurerm_managed_redis" "this" {
  name                      = var.name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  sku_name                  = var.sku_name
  high_availability_enabled = var.high_availability_enabled
  public_network_access     = "Disabled"

  default_database {
    client_protocol                    = "Encrypted" # TLS only
    access_keys_authentication_enabled = true
    eviction_policy                    = "AllKeysLRU" # it's a cache: evict instead of erroring when full
    # Single endpoint that behaves like non-clustered Redis, so ordinary
    # clients work without cluster support.
    clustering_policy = "EnterpriseCluster"
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "this" {
  name                = "pe-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "redis"
    private_connection_resource_id = azurerm_managed_redis.this.id
    subresource_names              = ["redisEnterprise"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "redis"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
