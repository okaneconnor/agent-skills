# =============================================================================
# Managed Identity Module Outputs
# =============================================================================

output "identity_id" {
  description = "ID of the managed identity"
  value       = azurerm_user_assigned_identity.identity.id
}

output "identity_name" {
  description = "Name of the managed identity"
  value       = azurerm_user_assigned_identity.identity.name
}

output "principal_id" {
  description = "Principal ID of the managed identity"
  value       = azurerm_user_assigned_identity.identity.principal_id
}

output "client_id" {
  description = "Client ID of the managed identity"
  value       = azurerm_user_assigned_identity.identity.client_id
}

output "tenant_id" {
  description = "Tenant ID of the managed identity"
  value       = azurerm_user_assigned_identity.identity.tenant_id
}
