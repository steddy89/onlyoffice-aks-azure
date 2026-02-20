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

  # Network rules - Allow during initial deployment for file share creation
  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }

  tags = var.tags
}

# File shares are dynamically provisioned by AKS CSI driver via PVCs
# Azure Policy blocks key-based auth, so azurerm_storage_share cannot be used
# The Azure Files CSI driver uses AKS managed identity for access

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
