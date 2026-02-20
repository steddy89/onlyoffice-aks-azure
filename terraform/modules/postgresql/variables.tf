variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "suffix" { type = string }
variable "unique_suffix" { type = string }
variable "environment" { type = string }
variable "db_subnet_id" { type = string }
variable "private_dns_zone_id" { type = string }
variable "key_vault_id" { type = string }
variable "postgresql_sku" { type = string }
variable "postgresql_version" { type = string }
variable "postgresql_storage_mb" { type = number }
variable "tags" { type = map(string) }

output "fqdn" { value = azurerm_postgresql_flexible_server.main.fqdn }
output "database_name" { value = azurerm_postgresql_flexible_server_database.onlyoffice.name }
output "admin_username" { value = azurerm_postgresql_flexible_server.main.administrator_login }
output "admin_password" {
  value     = random_password.postgresql.result
  sensitive = true
}
output "server_id" { value = azurerm_postgresql_flexible_server.main.id }
