# ==============================================================================
# Azure Cache for Redis Module
# ==============================================================================

resource "azurerm_redis_cache" "main" {
  name                = "redis-${var.suffix}-${var.unique_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = var.redis_capacity
  family              = var.redis_family
  sku_name            = var.redis_sku

  # Security
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  # Network - Premium SKU supports VNet injection
  subnet_id = var.redis_sku == "Premium" ? var.redis_subnet_id : null

  # Redis configuration
  redis_configuration {
    maxmemory_reserved              = 256
    maxmemory_delta                 = 256
    maxmemory_policy                = "allkeys-lru"
    rdb_backup_enabled              = var.redis_sku == "Premium" ? true : false
    rdb_backup_frequency            = var.redis_sku == "Premium" ? 60 : null
    rdb_backup_max_snapshot_count   = var.redis_sku == "Premium" ? 1 : null
  }

  # Availability zones for Premium
  zones = var.redis_sku == "Premium" ? ["1", "2", "3"] : null

  # Patching schedule
  patch_schedule {
    day_of_week    = "Sunday"
    start_hour_utc = 2
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# ---- Store Redis key in Key Vault ----
resource "azurerm_key_vault_secret" "redis_primary_key" {
  name         = "redis-primary-access-key"
  value        = azurerm_redis_cache.main.primary_access_key
  key_vault_id = var.key_vault_id

  content_type = "access-key"
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "redis_connection_string" {
  name         = "redis-connection-string"
  value        = azurerm_redis_cache.main.primary_connection_string
  key_vault_id = var.key_vault_id

  content_type = "connection-string"
  tags         = var.tags
}
