variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "suffix" { type = string }
variable "unique_suffix" { type = string }
variable "tenant_id" { type = string }
variable "object_id" { type = string }
variable "subnet_id" { type = string }
variable "virtual_network_id" { type = string }
variable "private_dns_zone_vnet_id" { type = string }
variable "keyvault_dns_zone_id" { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "tags" { type = map(string) }

output "key_vault_id" { value = azurerm_key_vault.main.id }
output "key_vault_uri" { value = azurerm_key_vault.main.vault_uri }
output "key_vault_name" { value = azurerm_key_vault.main.name }
output "onlyoffice_jwt_secret" {
  value     = random_password.jwt_secret.result
  sensitive = true
}
