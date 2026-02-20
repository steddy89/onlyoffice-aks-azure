# ==============================================================================
# ONLYOFFICE Document Server on Azure AKS - Main Configuration
#
# Architecture:
#   - AKS cluster with system + user node pools
#   - Azure Database for PostgreSQL Flexible Server
#   - Azure Cache for Redis
#   - Azure Files / Azure Blob Storage for document persistence
#   - Azure Key Vault for secrets management
#   - Azure Container Registry for image management
#   - Azure Monitor / Log Analytics for observability
#   - Azure Front Door / Application Gateway for ingress
#   - Private networking with VNet integration
#
# Reference: Azure Well-Architected Framework
# https://learn.microsoft.com/azure/well-architected/
# ==============================================================================

# ------------------------------------------------------------------------------
# Provider Configuration
# ------------------------------------------------------------------------------
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azuread" {}

provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config.host
    client_certificate     = base64decode(module.aks.kube_config.client_certificate)
    client_key             = base64decode(module.aks.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = module.aks.kube_config.host
  client_certificate     = base64decode(module.aks.kube_config.client_certificate)
  client_key             = base64decode(module.aks.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
}

# ------------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------------
data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

# ------------------------------------------------------------------------------
# Resource Group
# ------------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# Locals
# ------------------------------------------------------------------------------
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Application = "ONLYOFFICE Document Server"
    CostCenter  = var.cost_center
    Owner       = var.owner
  }

  suffix        = "${var.project_name}-${var.environment}"
  unique_suffix = substr(md5("${var.project_name}-${var.environment}-${var.location}"), 0, 8)
}

# ------------------------------------------------------------------------------
# Networking Module
# ------------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  suffix              = local.suffix
  environment         = var.environment

  vnet_address_space       = var.vnet_address_space
  aks_subnet_prefix        = var.aks_subnet_prefix
  db_subnet_prefix         = var.db_subnet_prefix
  redis_subnet_prefix      = var.redis_subnet_prefix
  appgw_subnet_prefix      = var.appgw_subnet_prefix
  private_endpoint_subnet  = var.private_endpoint_subnet

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# Key Vault Module
# ------------------------------------------------------------------------------
module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  suffix              = local.suffix
  unique_suffix       = local.unique_suffix
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id

  subnet_id                = module.networking.private_endpoint_subnet_id
  virtual_network_id       = module.networking.vnet_id
  private_dns_zone_vnet_id = module.networking.vnet_id

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# Container Registry Module
# ------------------------------------------------------------------------------
module "acr" {
  source = "./modules/acr"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  suffix              = local.suffix
  unique_suffix       = local.unique_suffix
  environment         = var.environment

  subnet_id          = module.networking.private_endpoint_subnet_id
  virtual_network_id = module.networking.vnet_id

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# AKS Module
# ------------------------------------------------------------------------------
module "aks" {
  source = "./modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  suffix              = local.suffix
  environment         = var.environment

  kubernetes_version    = var.kubernetes_version
  aks_subnet_id         = module.networking.aks_subnet_id
  appgw_subnet_id       = module.networking.appgw_subnet_id
  log_analytics_id      = module.monitoring.log_analytics_workspace_id
  acr_id                = module.acr.acr_id

  system_node_pool_vm_size  = var.system_node_pool_vm_size
  system_node_pool_count    = var.system_node_pool_count
  user_node_pool_vm_size    = var.user_node_pool_vm_size
  user_node_pool_min_count  = var.user_node_pool_min_count
  user_node_pool_max_count  = var.user_node_pool_max_count

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# PostgreSQL Module
# ------------------------------------------------------------------------------
module "postgresql" {
  source = "./modules/postgresql"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  suffix              = local.suffix
  unique_suffix       = local.unique_suffix
  environment         = var.environment

  db_subnet_id         = module.networking.db_subnet_id
  private_dns_zone_id  = module.networking.postgresql_dns_zone_id
  key_vault_id         = module.keyvault.key_vault_id

  postgresql_sku       = var.postgresql_sku
  postgresql_version   = var.postgresql_version
  postgresql_storage_mb = var.postgresql_storage_mb

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# Redis Module
# ------------------------------------------------------------------------------
module "redis" {
  source = "./modules/redis"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  suffix              = local.suffix
  unique_suffix       = local.unique_suffix
  environment         = var.environment

  redis_subnet_id      = module.networking.redis_subnet_id
  virtual_network_id   = module.networking.vnet_id

  redis_sku            = var.redis_sku
  redis_family         = var.redis_family
  redis_capacity       = var.redis_capacity

  key_vault_id         = module.keyvault.key_vault_id

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# Storage Module
# ------------------------------------------------------------------------------
module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  suffix              = local.suffix
  unique_suffix       = local.unique_suffix
  environment         = var.environment

  subnet_id          = module.networking.private_endpoint_subnet_id
  virtual_network_id = module.networking.vnet_id

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# Monitoring Module
# ------------------------------------------------------------------------------
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  suffix              = local.suffix
  environment         = var.environment

  aks_cluster_id = module.aks.aks_cluster_id

  alert_email       = var.alert_email
  log_retention_days = var.log_retention_days

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# ONLYOFFICE Helm Deployment
# ------------------------------------------------------------------------------
module "onlyoffice" {
  source = "./modules/onlyoffice-helm"

  depends_on = [
    module.aks,
    module.postgresql,
    module.redis,
    module.storage,
    module.keyvault,
  ]

  namespace           = var.onlyoffice_namespace
  replica_count       = var.onlyoffice_replica_count
  jwt_secret          = module.keyvault.onlyoffice_jwt_secret

  postgresql_host     = module.postgresql.fqdn
  postgresql_database = module.postgresql.database_name
  postgresql_user     = module.postgresql.admin_username
  postgresql_password = module.postgresql.admin_password

  redis_host          = module.redis.hostname
  redis_port          = module.redis.port
  redis_password      = module.redis.primary_access_key

  storage_account_name = module.storage.storage_account_name
  storage_account_key  = module.storage.storage_account_key
  storage_share_name   = module.storage.file_share_name

  domain_name         = var.domain_name
  tls_secret_name     = var.tls_secret_name
}
