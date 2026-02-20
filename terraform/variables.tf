# ==============================================================================
# Input Variables
# ==============================================================================

# ---- General ----
variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "onlyoffice"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus2"
}

variable "cost_center" {
  description = "Cost center tag for billing"
  type        = string
  default     = "IT-Infrastructure"
}

variable "owner" {
  description = "Owner tag"
  type        = string
  default     = "platform-team"
}

# ---- Networking ----
variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_prefix" {
  description = "AKS subnet CIDR"
  type        = string
  default     = "10.0.0.0/20"
}

variable "db_subnet_prefix" {
  description = "Database subnet CIDR"
  type        = string
  default     = "10.0.16.0/24"
}

variable "redis_subnet_prefix" {
  description = "Redis subnet CIDR"
  type        = string
  default     = "10.0.17.0/24"
}

variable "appgw_subnet_prefix" {
  description = "Application Gateway subnet CIDR"
  type        = string
  default     = "10.0.18.0/24"
}

variable "private_endpoint_subnet" {
  description = "Private endpoint subnet CIDR"
  type        = string
  default     = "10.0.19.0/24"
}

# ---- AKS ----
variable "kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.29"
}

variable "system_node_pool_vm_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "system_node_pool_count" {
  description = "Number of nodes in system node pool"
  type        = number
  default     = 3
}

variable "user_node_pool_vm_size" {
  description = "VM size for user (ONLYOFFICE) node pool"
  type        = string
  default     = "Standard_D8s_v5"
}

variable "user_node_pool_min_count" {
  description = "Min nodes in user node pool (autoscale)"
  type        = number
  default     = 2
}

variable "user_node_pool_max_count" {
  description = "Max nodes in user node pool (autoscale)"
  type        = number
  default     = 10
}

# ---- PostgreSQL ----
variable "postgresql_sku" {
  description = "PostgreSQL SKU name"
  type        = string
  default     = "GP_Standard_D4s_v3"
}

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "postgresql_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 65536
}

# ---- Redis ----
variable "redis_sku" {
  description = "Redis SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Premium"
}

variable "redis_family" {
  description = "Redis family (C for Basic/Standard, P for Premium)"
  type        = string
  default     = "P"
}

variable "redis_capacity" {
  description = "Redis capacity (size of the Redis cache)"
  type        = number
  default     = 1
}

# ---- ONLYOFFICE ----
variable "onlyoffice_namespace" {
  description = "Kubernetes namespace for ONLYOFFICE"
  type        = string
  default     = "onlyoffice"
}

variable "onlyoffice_replica_count" {
  description = "Number of ONLYOFFICE Document Server replicas"
  type        = number
  default     = 3
}

variable "domain_name" {
  description = "Domain name for ONLYOFFICE Document Server"
  type        = string
}

variable "tls_secret_name" {
  description = "Kubernetes TLS secret name for HTTPS"
  type        = string
  default     = "onlyoffice-tls"
}

# ---- Monitoring ----
variable "alert_email" {
  description = "Email address for monitoring alerts"
  type        = string
}

variable "log_retention_days" {
  description = "Log Analytics retention in days"
  type        = number
  default     = 90
}
