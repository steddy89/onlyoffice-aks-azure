# ==============================================================================
# PostgreSQL Flexible Server Module
# ==============================================================================

resource "random_password" "postgresql" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper        = 4
  min_lower        = 4
  min_numeric      = 4
  min_special      = 2
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${var.suffix}-${var.unique_suffix}"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = var.postgresql_version
  delegated_subnet_id    = var.db_subnet_id
  private_dns_zone_id    = var.private_dns_zone_id

  administrator_login    = "onlyoffice_admin"
  administrator_password = random_password.postgresql.result

  sku_name   = var.postgresql_sku
  storage_mb = var.postgresql_storage_mb

  backup_retention_days        = 35
  geo_redundant_backup_enabled = var.environment == "prod" ? true : false

  zone = "1"

  high_availability {
    mode                      = var.environment == "prod" ? "ZoneRedundant" : "Disabled"
    standby_availability_zone = var.environment == "prod" ? "2" : null
  }

  maintenance_window {
    day_of_week  = 0
    start_hour   = 2
    start_minute = 0
  }

  authentication {
    password_auth_enabled         = true
    active_directory_auth_enabled = true
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

data "azurerm_client_config" "current" {}

# ---- Database ----
resource "azurerm_postgresql_flexible_server_database" "onlyoffice" {
  name      = "onlyoffice"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# ---- Server Configuration ----
resource "azurerm_postgresql_flexible_server_configuration" "ssl" {
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_checkpoints" {
  name      = "log_checkpoints"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_connections" {
  name      = "log_connections"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "connection_throttling" {
  name      = "connection_throttle.enable"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}

# ---- Store password in Key Vault ----
resource "azurerm_key_vault_secret" "postgresql_password" {
  name         = "postgresql-admin-password"
  value        = random_password.postgresql.result
  key_vault_id = var.key_vault_id

  content_type = "password"
  
  tags = var.tags
}

resource "azurerm_key_vault_secret" "postgresql_connection_string" {
  name         = "postgresql-connection-string"
  value        = "host=${azurerm_postgresql_flexible_server.main.fqdn} port=5432 dbname=onlyoffice user=onlyoffice_admin password=${random_password.postgresql.result} sslmode=require"
  key_vault_id = var.key_vault_id

  content_type = "connection-string"

  tags = var.tags
}

# ---- Diagnostic Settings ----
resource "azurerm_monitor_diagnostic_setting" "postgresql" {
  name               = "diag-psql-${var.suffix}"
  target_resource_id = azurerm_postgresql_flexible_server.main.id

  enabled_log {
    category = "PostgreSQLLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
