# =============================================================================
# Hub VNet Module Outputs
# =============================================================================

output "vnet_id" {
  description = "ID of the hub VNet"
  value       = azurerm_virtual_network.hub.id
}

output "vnet_name" {
  description = "Name of the hub VNet"
  value       = azurerm_virtual_network.hub.name
}

output "vnet_address_space" {
  description = "Address space of the hub VNet"
  value       = azurerm_virtual_network.hub.address_space
}

output "firewall_subnet_id" {
  description = "ID of the Azure Firewall subnet"
  value       = azurerm_subnet.firewall.id
}

output "gateway_subnet_id" {
  description = "ID of the Gateway subnet"
  value       = azurerm_subnet.gateway.id
}

output "bastion_subnet_id" {
  description = "ID of the Azure Bastion subnet"
  value       = azurerm_subnet.bastion.id
}

output "management_subnet_id" {
  description = "ID of the Management subnet"
  value       = azurerm_subnet.management.id
}

output "bastion_host_id" {
  description = "ID of the Azure Bastion host (if deployed)"
  value       = var.enable_bastion ? azurerm_bastion_host.hub["bastion"].id : null
}

output "bastion_host_dns_name" {
  description = "DNS name of the Azure Bastion host (if deployed)"
  value       = var.enable_bastion ? azurerm_bastion_host.hub["bastion"].dns_name : null
}

output "route_table_id" {
  description = "ID of the hub route table"
  value       = azurerm_route_table.hub.id
}
