# =============================================================================
# Key Vault Module Outputs
# =============================================================================

output "vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.vault.id
}

output "vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.vault.name
}

output "vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.vault.vault_uri
}

output "vault_tenant_id" {
  description = "Tenant ID of the Key Vault"
  value       = azurerm_key_vault.vault.tenant_id
}

output "private_endpoint_id" {
  description = "ID of the private endpoint (if created)"
  value       = var.private_endpoint_subnet_id != null ? azurerm_private_endpoint.vault["pe"].id : null
}

output "private_endpoint_ip" {
  description = "Private IP of the private endpoint (if created)"
  value       = var.private_endpoint_subnet_id != null ? azurerm_private_endpoint.vault["pe"].private_service_connection[0].private_ip_address : null
}
