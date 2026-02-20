# ==============================================================================
# Terraform Variable Definitions - Development Environment
# ==============================================================================

project_name = "onlyoffice"
environment  = "dev"
location     = "eastus2"
cost_center  = "IT-Development"
owner        = "dev-team"

# Networking
vnet_address_space      = ["10.1.0.0/16"]
aks_subnet_prefix       = "10.1.0.0/20"
db_subnet_prefix        = "10.1.16.0/24"
redis_subnet_prefix     = "10.1.17.0/24"
appgw_subnet_prefix     = "10.1.18.0/24"
private_endpoint_subnet = "10.1.19.0/24"

# AKS - smaller for dev
kubernetes_version       = "1.33"
system_node_pool_vm_size = "Standard_D2s_v5"
system_node_pool_count   = 1
user_node_pool_vm_size   = "Standard_D4s_v5"
user_node_pool_min_count = 1
user_node_pool_max_count = 3

# PostgreSQL - smaller for dev
postgresql_sku        = "B_Standard_B2s"
postgresql_version    = "15"
postgresql_storage_mb = 32768

# Redis - Standard for dev
redis_sku      = "Standard"
redis_family   = "C"
redis_capacity = 1

# ONLYOFFICE
onlyoffice_namespace     = "onlyoffice"
onlyoffice_replica_count = 1
domain_name              = "docs-dev.example.com"
tls_secret_name          = "onlyoffice-tls"

# Monitoring
alert_email        = "dev-team@example.com"
log_retention_days = 30
