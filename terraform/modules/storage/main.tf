# ==============================================================================
# Storage Module - Azure Files for document persistence
# ==============================================================================

resource "azurerm_storage_account" "main" {
  name                     = "st${replace(var.suffix, "-", "")}${var.unique_suffix}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Premium"
  account_replication_type = var.environment == "prod" ? "ZRS" : "LRS"
  account_kind             = "FileStorage"

  # Security
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  https_traffic_only_enabled      = true

  # Network rules
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  # Blob soft delete
  blob_properties {
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
    versioning_enabled = true
  }

  tags = var.tags
}

# ---- Azure File Share for ONLYOFFICE data ----
resource "azurerm_storage_share" "onlyoffice_data" {
  name                 = "onlyoffice-data"
  storage_account_name = azurerm_storage_account.main.name
  quota                = 100
  enabled_protocol     = "SMB"

  acl {
    id = "default-acl"
    access_policy {
      permissions = "rwdl"
    }
  }
}

resource "azurerm_storage_share" "onlyoffice_logs" {
  name                 = "onlyoffice-logs"
  storage_account_name = azurerm_storage_account.main.name
  quota                = 50
  enabled_protocol     = "SMB"
}

# ---- Private Endpoint ----
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-st-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "storage-connection"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  tags = var.tags
}

# ---- Backup Container for DR ----
resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
