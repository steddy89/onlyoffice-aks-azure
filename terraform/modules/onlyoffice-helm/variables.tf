variable "namespace" { type = string }
variable "replica_count" { type = number }
variable "jwt_secret" { type = string; sensitive = true }
variable "postgresql_host" { type = string }
variable "postgresql_database" { type = string }
variable "postgresql_user" { type = string }
variable "postgresql_password" { type = string; sensitive = true }
variable "redis_host" { type = string }
variable "redis_port" { type = number }
variable "redis_password" { type = string; sensitive = true }
variable "storage_account_name" { type = string }
variable "storage_account_key" { type = string; sensitive = true }
variable "storage_share_name" { type = string }
variable "domain_name" { type = string }
variable "tls_secret_name" { type = string }
