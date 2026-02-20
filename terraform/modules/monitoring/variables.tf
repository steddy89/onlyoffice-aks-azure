variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "suffix" { type = string }
variable "environment" { type = string }
variable "aks_cluster_id" { type = string }
variable "alert_email" { type = string }
variable "log_retention_days" { type = number }
variable "tags" { type = map(string) }

output "log_analytics_workspace_id" { value = azurerm_log_analytics_workspace.main.id }
output "log_analytics_workspace_name" { value = azurerm_log_analytics_workspace.main.name }
output "app_insights_instrumentation_key" {
  value     = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}
output "app_insights_connection_string" {
  value     = azurerm_application_insights.main.connection_string
  sensitive = true
}
