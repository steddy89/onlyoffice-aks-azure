variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "suffix" { type = string }
variable "unique_suffix" { type = string }
variable "environment" { type = string }
variable "redis_subnet_id" { type = string }
variable "virtual_network_id" { type = string }
variable "redis_sku" { type = string }
variable "redis_family" { type = string }
variable "redis_capacity" { type = number }
variable "key_vault_id" { type = string }
variable "tags" { type = map(string) }

output "hostname" { value = azurerm_redis_cache.main.hostname }
output "port" { value = azurerm_redis_cache.main.ssl_port }
output "primary_access_key" {
  value     = azurerm_redis_cache.main.primary_access_key
  sensitive = true
}
output "redis_id" { value = azurerm_redis_cache.main.id }
