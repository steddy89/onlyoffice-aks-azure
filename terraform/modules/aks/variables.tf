variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "suffix" { type = string }
variable "environment" { type = string }
variable "kubernetes_version" { type = string }
variable "aks_subnet_id" { type = string }
variable "appgw_subnet_id" { type = string }
variable "log_analytics_id" { type = string }
variable "acr_id" { type = string }
variable "system_node_pool_vm_size" { type = string }
variable "system_node_pool_count" { type = number }
variable "user_node_pool_vm_size" { type = string }
variable "user_node_pool_min_count" { type = number }
variable "user_node_pool_max_count" { type = number }
variable "tags" { type = map(string) }

output "aks_cluster_id" { value = azurerm_kubernetes_cluster.main.id }
output "cluster_name" { value = azurerm_kubernetes_cluster.main.name }
output "cluster_fqdn" { value = azurerm_kubernetes_cluster.main.fqdn }

output "kube_config" {
  value = {
    host                   = azurerm_kubernetes_cluster.main.kube_config[0].host
    client_certificate     = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
    client_key             = azurerm_kubernetes_cluster.main.kube_config[0].client_key
    cluster_ca_certificate = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  }
  sensitive = true
}

output "kube_config_raw" {
  value     = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive = true
}

output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.main.oidc_issuer_url
}
