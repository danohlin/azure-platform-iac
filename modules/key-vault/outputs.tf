output "id" {
  description = "Only available once RBAC has propagated, so dependents can write secrets."
  value       = azurerm_key_vault.this.id
  depends_on  = [time_sleep.rbac_propagation]
}

output "uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "name" {
  value = azurerm_key_vault.this.name
}

output "greeting_secret_id" {
  description = "Versionless secret ID, for Key Vault references in app settings."
  value       = azurerm_key_vault_secret.greeting.versionless_id
}
