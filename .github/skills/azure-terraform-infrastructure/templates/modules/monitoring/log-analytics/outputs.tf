# =============================================================================
# Log Analytics Module Outputs
# =============================================================================

output "workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.workspace.id
}

output "workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.workspace.name
}

output "workspace_customer_id" {
  description = "Workspace ID (GUID) for agents"
  value       = azurerm_log_analytics_workspace.workspace.workspace_id
}

output "primary_shared_key" {
  description = "Primary shared key for the workspace"
  value       = azurerm_log_analytics_workspace.workspace.primary_shared_key
  sensitive   = true
}

output "secondary_shared_key" {
  description = "Secondary shared key for the workspace"
  value       = azurerm_log_analytics_workspace.workspace.secondary_shared_key
  sensitive   = true
}

output "data_collection_rule_ids" {
  description = "Map of data collection rule names to IDs"
  value       = { for k, v in azurerm_monitor_data_collection_rule.dcr : k => v.id }
}
