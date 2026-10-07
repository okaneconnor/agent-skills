# =============================================================================
# Staging Environment - Outputs
# =============================================================================

output "hub_vnet_id" {
  description = "ID of the hub VNet"
  value       = module.hub_vnet.vnet_id
}

output "aks_spoke_vnet_id" {
  description = "ID of the AKS spoke VNet"
  value       = module.aks_spoke_vnet.vnet_id
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.aks.cluster_fqdn
}

output "aks_kube_config" {
  description = "Kubernetes config for kubectl"
  value       = module.aks.kube_config
  sensitive   = true
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = module.aks.oidc_issuer_url
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.vault_uri
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.key_vault.vault_name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.storage_account_name
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.log_analytics.workspace_id
}

output "firewall_private_ip" {
  description = "Private IP of Azure Firewall"
  value       = var.enable_firewall ? module.azure_firewall["firewall"].firewall_private_ip : null
}
