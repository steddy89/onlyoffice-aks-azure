# ==============================================================================
# AKS Module - Azure Kubernetes Service
# ==============================================================================

resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-aks-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-${var.suffix}"
  kubernetes_version  = var.kubernetes_version

  # Use managed identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # System node pool - runs kube-system workloads
  default_node_pool {
    name                = "system"
    vm_size             = var.system_node_pool_vm_size
    node_count          = var.system_node_pool_count
    vnet_subnet_id      = var.aks_subnet_id
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
    type                = "VirtualMachineScaleSets"
    zones               = ["2", "3"]
    max_pods            = 50

    node_labels = {
      "nodepool" = "system"
    }

    upgrade_settings {
      max_surge = "33%"
    }

    tags = var.tags
  }

  # Network configuration - Azure CNI for better network integration
  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    service_cidr      = "172.16.0.0/16"
    dns_service_ip    = "172.16.0.10"
  }

  # AGIC - Application Gateway Ingress Controller
  ingress_application_gateway {
    subnet_id = var.appgw_subnet_id
  }

  # Azure AD RBAC
  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = []
  }

  # OMS Agent for monitoring
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_id
  }

  # Key Vault secrets provider
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Maintenance window
  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [0, 1, 2, 3, 4]
    }
  }

  # Auto-upgrade channel
  automatic_channel_upgrade = "patch"

  # Azure Policy
  azure_policy_enabled = true

  # Workload Identity
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  # Private cluster for production
  private_cluster_enabled = var.environment == "prod" ? true : false

  # SKU tier - Standard for production SLA
  sku_tier = var.environment == "prod" ? "Standard" : "Free"

  tags = var.tags
}

# ---- User Node Pool for ONLYOFFICE workloads ----
resource "azurerm_kubernetes_cluster_node_pool" "onlyoffice" {
  name                  = "onlyoffice"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_node_pool_vm_size
  vnet_subnet_id        = var.aks_subnet_id

  enable_auto_scaling = true
  min_count           = var.user_node_pool_min_count
  max_count           = var.user_node_pool_max_count
  os_disk_size_gb     = 256
  os_disk_type        = "Managed"
  zones               = ["2", "3"]
  max_pods            = 30

  node_labels = {
    "nodepool"    = "onlyoffice"
    "workload"    = "document-server"
  }

  node_taints = [
    "workload=onlyoffice:NoSchedule"
  ]

  upgrade_settings {
    max_surge = "33%"
  }

  tags = var.tags
}

# ---- ACR Pull Role Assignment ----
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}

# ---- Diagnostic Settings ----
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "diag-aks-${var.suffix}"
  target_resource_id         = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = var.log_analytics_id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
