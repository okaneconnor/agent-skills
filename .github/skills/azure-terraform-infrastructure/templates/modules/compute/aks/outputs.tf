# =============================================================================
# AKS Module Outputs
# =============================================================================

output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "cluster_private_fqdn" {
  description = "Private FQDN of the AKS cluster (if private)"
  value       = azurerm_kubernetes_cluster.aks.private_fqdn
}

output "kube_config" {
  description = "Kubernetes configuration (sensitive)"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "kube_admin_config" {
  description = "Kubernetes admin configuration (sensitive)"
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
  sensitive   = true
}

output "host" {
  description = "Kubernetes API server host"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive   = true
}

output "client_certificate" {
  description = "Kubernetes client certificate"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Kubernetes client key"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "node_resource_group" {
  description = "Name of the node resource group"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "kubelet_identity" {
  description = "Kubelet managed identity"
  value = {
    client_id   = azurerm_kubernetes_cluster.aks.kubelet_identity[0].client_id
    object_id   = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
    resource_id = azurerm_kubernetes_cluster.aks.kubelet_identity[0].user_assigned_identity_id
  }
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "identity" {
  description = "AKS cluster managed identity"
  value = {
    principal_id = azurerm_user_assigned_identity.aks.principal_id
    client_id    = azurerm_user_assigned_identity.aks.client_id
    id           = azurerm_user_assigned_identity.aks.id
  }
}

output "key_vault_secrets_provider_identity" {
  description = "Key Vault Secrets Provider identity (if enabled)"
  value       = var.enable_key_vault_secrets_provider ? azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0] : null
}
