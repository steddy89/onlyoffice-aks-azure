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
  value     = ""
  sensitive = true
}
output "file_share_name" { value = "onlyoffice-data" }
output "storage_account_id" { value = azurerm_storage_account.main.id }
