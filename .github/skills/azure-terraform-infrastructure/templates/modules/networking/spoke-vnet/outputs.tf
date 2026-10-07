# =============================================================================
# Spoke VNet Module Outputs
# =============================================================================

output "vnet_id" {
  description = "ID of the spoke VNet"
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "Name of the spoke VNet"
  value       = azurerm_virtual_network.spoke.name
}

output "vnet_address_space" {
  description = "Address space of the spoke VNet"
  value       = azurerm_virtual_network.spoke.address_space
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to their address prefixes"
  value       = { for k, v in azurerm_subnet.subnets : k => v.address_prefixes[0] }
}

output "route_table_id" {
  description = "ID of the route table (if created)"
  value       = var.create_route_table ? azurerm_route_table.spoke[0].id : null
}
