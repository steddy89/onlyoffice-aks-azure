variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "suffix" { type = string }
variable "environment" { type = string }
variable "aks_cluster_id" { type = string }
variable "alert_email" { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "log_analytics_workspace_name" { type = string }
variable "tags" { type = map(string) }

output "log_analytics_workspace_id" { value = var.log_analytics_workspace_id }
output "log_analytics_workspace_name" { value = var.log_analytics_workspace_name }
output "app_insights_instrumentation_key" {
  value     = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}
output "app_insights_connection_string" {
  value     = azurerm_application_insights.main.connection_string
  sensitive = true
}
