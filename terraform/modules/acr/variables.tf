variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "suffix" { type = string }
variable "unique_suffix" { type = string }
variable "environment" { type = string }
variable "subnet_id" { type = string }
variable "virtual_network_id" { type = string }
variable "tags" { type = map(string) }

output "acr_id" { value = azurerm_container_registry.main.id }
output "login_server" { value = azurerm_container_registry.main.login_server }
output "acr_name" { value = azurerm_container_registry.main.name }
