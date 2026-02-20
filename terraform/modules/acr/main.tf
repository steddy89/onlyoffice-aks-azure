# ==============================================================================
# Azure Container Registry Module
# ==============================================================================

resource "azurerm_container_registry" "main" {
  name                = "acr${replace(var.suffix, "-", "")}${var.unique_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.environment == "prod" ? "Premium" : "Standard"
  admin_enabled       = false

  # Geo-replication for production
  dynamic "georeplications" {
    for_each = var.environment == "prod" ? ["westus2"] : []
    content {
      location                = georeplications.value
      zone_redundancy_enabled = true
    }
  }

  # Network rules (Premium only)
  dynamic "network_rule_set" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      default_action = "Deny"
    }
  }

  # Content trust
  trust_policy {
    enabled = var.environment == "prod" ? true : false
  }

  # Retention policy
  retention_policy {
    enabled = true
    days    = 30
  }

  # Zone redundancy
  zone_redundancy_enabled = var.environment == "prod" ? true : false

  tags = var.tags
}

# ---- Private Endpoint (prod only) ----
resource "azurerm_private_endpoint" "acr" {
  count = var.environment == "prod" ? 1 : 0

  name                = "pe-acr-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "acr-connection"
    private_connection_resource_id = azurerm_container_registry.main.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  tags = var.tags
}
