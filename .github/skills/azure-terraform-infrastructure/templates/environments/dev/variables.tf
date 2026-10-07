# =============================================================================
# Dev Environment - Variables
# =============================================================================

variable "project_name" {
  description = "Name of the project (used in resource naming)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "location_short" {
  description = "Short name for the Azure region"
  type        = string
  default     = "eus"
}

# Network CIDRs
variable "hub_vnet_cidr" {
  description = "CIDR for hub VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_spoke_cidr" {
  description = "CIDR for AKS spoke VNet"
  type        = string
  default     = "10.1.0.0/16"
}

variable "vm_spoke_cidr" {
  description = "CIDR for VM spoke VNet"
  type        = string
  default     = "10.2.0.0/16"
}

# Feature Flags
variable "enable_bastion" {
  description = "Enable Azure Bastion"
  type        = bool
  default     = true
}

variable "enable_firewall" {
  description = "Enable Azure Firewall"
  type        = bool
  default     = false # Disabled by default for dev cost savings
}

# Access Control
variable "key_vault_admin_object_ids" {
  description = "Object IDs for Key Vault administrators"
  type        = list(string)
  default     = []
}

variable "aks_admin_group_object_ids" {
  description = "Azure AD group object IDs for AKS cluster admins"
  type        = list(string)
  default     = []
}
