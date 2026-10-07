# =============================================================================
# VM Module Outputs
# =============================================================================

output "linux_vm_ids" {
  description = "Map of Linux VM names to their IDs"
  value       = { for k, v in azurerm_linux_virtual_machine.vm : k => v.id }
}

output "windows_vm_ids" {
  description = "Map of Windows VM names to their IDs"
  value       = { for k, v in azurerm_windows_virtual_machine.vm : k => v.id }
}

output "linux_vm_private_ips" {
  description = "Map of Linux VM names to their private IPs"
  value       = { for k, v in azurerm_linux_virtual_machine.vm : k => v.private_ip_address }
}

output "windows_vm_private_ips" {
  description = "Map of Windows VM names to their private IPs"
  value       = { for k, v in azurerm_windows_virtual_machine.vm : k => v.private_ip_address }
}

output "linux_vm_identities" {
  description = "Map of Linux VM names to their managed identities"
  value       = { for k, v in azurerm_linux_virtual_machine.vm : k => v.identity[0] }
}

output "windows_vm_identities" {
  description = "Map of Windows VM names to their managed identities"
  value       = { for k, v in azurerm_windows_virtual_machine.vm : k => v.identity[0] }
}

output "network_interface_ids" {
  description = "Map of VM names to their network interface IDs"
  value       = { for k, v in azurerm_network_interface.vm : k => v.id }
}
