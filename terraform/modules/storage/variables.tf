variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "suffix" { type = string }
variable "unique_suffix" { type = string }
variable "environment" { type = string }
variable "subnet_id" { type = string }
variable "virtual_network_id" { type = string }
variable "tags" { type = map(string) }

output "storage_account_name" { value = azurerm_storage_account.main.name }
output "storage_account_key" {
  value     = azurerm_storage_account.main.primary_access_key
  sensitive = true
}
output "file_share_name" { value = azurerm_storage_share.onlyoffice_data.name }
output "storage_account_id" { value = azurerm_storage_account.main.id }
