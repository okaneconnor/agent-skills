# =============================================================================
# AKS Module Variables
# =============================================================================

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "location_short" {
  description = "Short name for the Azure region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = null # Uses latest stable version if null
}

variable "subnet_id" {
  description = "ID of the subnet for AKS nodes"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for node pools"
  type        = list(string)
  default     = ["1", "2", "3"]
}

# System Node Pool
variable "system_node_pool" {
  description = "Configuration for the system node pool"
  type = object({
    vm_size             = string
    node_count          = number
    min_count           = optional(number, 2)
    max_count           = optional(number, 5)
    enable_auto_scaling = optional(bool, true)
    max_pods            = optional(number, 30)
    os_disk_size_gb     = optional(number, 128)
    os_disk_type        = optional(string, "Managed")
  })
  default = {
    vm_size             = "Standard_D4s_v5"
    node_count          = 2
    min_count           = 2
    max_count           = 5
    enable_auto_scaling = true
    max_pods            = 30
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
  }
}

# Additional Node Pools
variable "node_pools" {
  description = "Map of additional node pools to create"
  type = map(object({
    vm_size             = string
    node_count          = number
    min_count           = optional(number, 1)
    max_count           = optional(number, 10)
    enable_auto_scaling = optional(bool, true)
    max_pods            = optional(number, 30)
    os_disk_size_gb     = optional(number, 128)
    os_disk_type        = optional(string, "Managed")
    os_type             = optional(string, "Linux")
    mode                = optional(string, "User")
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), [])
    priority            = optional(string, "Regular")
    spot_max_price      = optional(number, -1)
  }))
  default = {}
}

# Network Configuration
variable "network_plugin" {
  description = "Network plugin (azure or kubenet)"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "Network plugin must be 'azure' or 'kubenet'."
  }
}

variable "network_plugin_mode" {
  description = "Network plugin mode for Azure CNI (overlay or bridge)"
  type        = string
  default     = "overlay"
}

variable "network_policy" {
  description = "Network policy (azure, calico, or null)"
  type        = string
  default     = "azure"
}

variable "dns_service_ip" {
  description = "DNS service IP address"
  type        = string
  default     = "10.0.0.10"
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes services"
  type        = string
  default     = "10.0.0.0/16"
}

variable "outbound_type" {
  description = "Outbound type (loadBalancer, userDefinedRouting, managedNATGateway)"
  type        = string
  default     = "loadBalancer"
}

# Azure AD Integration
variable "enable_azure_ad_integration" {
  description = "Enable Azure AD integration"
  type        = bool
  default     = true
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes"
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs for cluster admins"
  type        = list(string)
  default     = []
}

# Features
variable "enable_key_vault_secrets_provider" {
  description = "Enable Key Vault Secrets Provider addon"
  type        = bool
  default     = true
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy addon"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable workload identity"
  type        = bool
  default     = true
}

# Private Cluster
variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

variable "private_cluster_public_fqdn_enabled" {
  description = "Enable public FQDN for private cluster"
  type        = bool
  default     = false
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for private cluster"
  type        = string
  default     = null
}

# Monitoring
variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
  default     = null
}

# Maintenance
variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    frequency   = string
    interval    = number
    duration    = number
    day_of_week = string
    start_time  = string
    utc_offset  = string
  })
  default = null
}

variable "automatic_upgrade_channel" {
  description = "Automatic upgrade channel (none, patch, rapid, stable, node-image)"
  type        = string
  default     = "patch"
}

# Resource Group
variable "node_resource_group_id" {
  description = "ID of the node resource group (if pre-created)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
