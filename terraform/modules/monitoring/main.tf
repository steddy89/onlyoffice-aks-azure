# ==============================================================================
# Monitoring Module - App Insights, Alerts, Dashboards
# Log Analytics Workspace is created in root main.tf and passed in.
# ==============================================================================

resource "azurerm_application_insights" "main" {
  name                = "appi-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.log_analytics_workspace_id
  application_type    = "web"

  tags = var.tags
}

# ---- Container Insights Solution ----
resource "azurerm_log_analytics_solution" "containers" {
  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = var.log_analytics_workspace_id
  workspace_name        = var.log_analytics_workspace_name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

# ---- Action Group ----
resource "azurerm_monitor_action_group" "critical" {
  name                = "ag-critical-${var.suffix}"
  resource_group_name = var.resource_group_name
  short_name          = "critical"

  email_receiver {
    name          = "admin-email"
    email_address = var.alert_email
  }

  tags = var.tags
}

# ---- Metric Alerts ----

# AKS Node CPU > 85%
resource "azurerm_monitor_metric_alert" "aks_cpu" {
  name                = "alert-aks-cpu-${var.suffix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "AKS node CPU utilization > 85%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  tags = var.tags
}

# AKS Node Memory > 85%
resource "azurerm_monitor_metric_alert" "aks_memory" {
  name                = "alert-aks-memory-${var.suffix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "AKS node memory utilization > 85%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  tags = var.tags
}

# AKS Pod Failed count
resource "azurerm_monitor_metric_alert" "aks_pod_failed" {
  name                = "alert-aks-pod-failed-${var.suffix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "Pods in failed state detected"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "kube_pod_status_phase"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0

    dimension {
      name     = "phase"
      operator = "Include"
      values   = ["Failed"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  tags = var.tags
}

# ---- Log-based Alerts ----

# ONLYOFFICE container restart alert
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "container_restarts" {
  name                = "alert-container-restarts-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  scopes              = [var.log_analytics_workspace_id]
  description         = "ONLYOFFICE container restarting frequently"
  severity            = 1

  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"

  criteria {
    query = <<-QUERY
      KubePodInventory
      | where Namespace == "onlyoffice"
      | where ContainerRestartCount > 3
      | summarize RestartCount = max(ContainerRestartCount) by Name, Namespace
    QUERY

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  action {
    action_groups = [azurerm_monitor_action_group.critical.id]
  }

  tags = var.tags
}

# ---- Dashboards ----
resource "azurerm_portal_dashboard" "onlyoffice" {
  name                = "dash-onlyoffice-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  dashboard_properties = templatefile("${path.module}/dashboard.json", {
    subscription_id    = data.azurerm_subscription.current.subscription_id
    resource_group     = var.resource_group_name
    log_analytics_id   = var.log_analytics_workspace_id
    aks_cluster_id     = var.aks_cluster_id
  })

  tags = var.tags
}

data "azurerm_subscription" "current" {}
