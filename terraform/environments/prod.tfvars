# ==============================================================================
# Terraform Variable Definitions - Production Environment
# ==============================================================================

project_name = "onlyoffice"
environment  = "prod"
location     = "eastus2"
cost_center  = "IT-Infrastructure"
owner        = "platform-team"

# Networking
vnet_address_space      = ["10.0.0.0/16"]
aks_subnet_prefix       = "10.0.0.0/20"
db_subnet_prefix        = "10.0.16.0/24"
redis_subnet_prefix     = "10.0.17.0/24"
appgw_subnet_prefix     = "10.0.18.0/24"
private_endpoint_subnet = "10.0.19.0/24"

# AKS
kubernetes_version       = "1.29"
system_node_pool_vm_size = "Standard_D4s_v5"
system_node_pool_count   = 3
user_node_pool_vm_size   = "Standard_D8s_v5"
user_node_pool_min_count = 2
user_node_pool_max_count = 10

# PostgreSQL
postgresql_sku        = "GP_Standard_D4s_v3"
postgresql_version    = "15"
postgresql_storage_mb = 65536

# Redis
redis_sku      = "Premium"
redis_family   = "P"
redis_capacity = 1

# ONLYOFFICE
onlyoffice_namespace     = "onlyoffice"
onlyoffice_replica_count = 3
domain_name              = "docs.example.com"
tls_secret_name          = "onlyoffice-tls"

# Monitoring
alert_email        = "oncall@example.com"
log_retention_days = 90
