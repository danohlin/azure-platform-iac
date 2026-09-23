output "resource_group_name" {
  value = module.resource_group.name
}

output "web_app_url" {
  value = module.app_service.url
}

output "container_app_url" {
  value = module.container_apps.url
}

output "function_app_url" {
  value = module.function_app.url
}

output "key_vault_name" {
  value = module.key_vault.name
}

output "storage_account_name" {
  value = module.storage.name
}

output "acr_name" {
  value = module.container_registry.name
}

output "sql_server_fqdn" {
  value = module.sql.server_fqdn
}

output "sql_database_name" {
  value = module.sql.database_name
}
