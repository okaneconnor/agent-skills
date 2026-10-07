# =============================================================================
# Storage Account Module Outputs
# =============================================================================

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.storage.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.storage.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.storage.primary_blob_endpoint
}

output "primary_file_endpoint" {
  description = "Primary file endpoint"
  value       = azurerm_storage_account.storage.primary_file_endpoint
}

output "primary_queue_endpoint" {
  description = "Primary queue endpoint"
  value       = azurerm_storage_account.storage.primary_queue_endpoint
}

output "primary_table_endpoint" {
  description = "Primary table endpoint"
  value       = azurerm_storage_account.storage.primary_table_endpoint
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.storage.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Secondary access key"
  value       = azurerm_storage_account.storage.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string"
  value       = azurerm_storage_account.storage.primary_connection_string
  sensitive   = true
}

output "identity" {
  description = "Managed identity of the storage account"
  value = {
    principal_id = azurerm_storage_account.storage.identity[0].principal_id
    tenant_id    = azurerm_storage_account.storage.identity[0].tenant_id
  }
}

output "container_ids" {
  description = "Map of container names to IDs"
  value       = { for k, v in azurerm_storage_container.containers : k => v.id }
}
