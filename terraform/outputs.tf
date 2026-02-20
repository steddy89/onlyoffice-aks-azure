# ==============================================================================
# Outputs
# ==============================================================================

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.cluster_name
}

output "aks_cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = module.aks.cluster_fqdn
}

output "acr_login_server" {
  description = "ACR login server"
  value       = module.acr.login_server
}

output "postgresql_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = module.postgresql.fqdn
  sensitive   = true
}

output "redis_hostname" {
  description = "Redis hostname"
  value       = module.redis.hostname
  sensitive   = true
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.keyvault.key_vault_uri
}

output "storage_account_name" {
  description = "Storage account name"
  value       = module.storage.storage_account_name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = module.monitoring.log_analytics_workspace_id
}

output "kube_config" {
  description = "Kube config (sensitive)"
  value       = module.aks.kube_config_raw
  sensitive   = true
}

output "onlyoffice_endpoint" {
  description = "ONLYOFFICE Document Server endpoint"
  value       = "https://${var.domain_name}"
}
