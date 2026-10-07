# =============================================================================
# Production Environment - Variables
# =============================================================================

variable "project_name" {
  description = "Name of the project"
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

variable "hub_vnet_cidr" {
  description = "CIDR for hub VNet"
  type        = string
  default     = "10.20.0.0/16"
}

variable "aks_spoke_cidr" {
  description = "CIDR for AKS spoke VNet"
  type        = string
  default     = "10.21.0.0/16"
}

variable "vm_spoke_cidr" {
  description = "CIDR for VM spoke VNet"
  type        = string
  default     = "10.22.0.0/16"
}

variable "enable_bastion" {
  description = "Enable Azure Bastion"
  type        = bool
  default     = true
}

variable "enable_private_cluster" {
  description = "Enable private AKS cluster"
  type        = bool
  default     = true
}

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

variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for network access"
  type        = list(string)
  default     = []
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "Engineering"
}

variable "compliance_level" {
  description = "Compliance level (e.g., SOC2, HIPAA)"
  type        = string
  default     = "SOC2"
}
