# =============================================================================
# NSG Module Outputs
# =============================================================================

output "nsg_id" {
  description = "ID of the NSG"
  value       = azurerm_network_security_group.nsg.id
}

output "nsg_name" {
  description = "Name of the NSG"
  value       = azurerm_network_security_group.nsg.name
}

output "security_rule_ids" {
  description = "Map of security rule names to their IDs"
  value       = { for k, v in azurerm_network_security_rule.rules : k => v.id }
}
