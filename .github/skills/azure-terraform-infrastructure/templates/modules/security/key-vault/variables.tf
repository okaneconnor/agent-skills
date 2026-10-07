# =============================================================================
# Key Vault Module Variables
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

variable "vault_name" {
  description = "Name suffix for the Key Vault (max 24 chars total)"
  type        = string
}

variable "sku_name" {
  description = "SKU for Key Vault (standard or premium)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU must be 'standard' or 'premium'."
  }
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention days (7-90)"
  type        = number
  default     = 90
}

variable "purge_protection_enabled" {
  description = "Enable purge protection"
  type        = bool
  default     = true
}

variable "enabled_for_disk_encryption" {
  description = "Enable for disk encryption"
  type        = bool
  default     = true
}

variable "enabled_for_deployment" {
  description = "Enable for VM deployment"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Enable for ARM template deployment"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "network_acls" {
  description = "Network ACL configuration"
  type = object({
    default_action             = string
    bypass                     = string
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = {
    default_action             = "Allow"
    bypass                     = "AzureServices"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}

# RBAC Assignments
variable "administrator_object_ids" {
  description = "Object IDs for Key Vault Administrators"
  type        = list(string)
  default     = []
}

variable "secrets_user_object_ids" {
  description = "Object IDs for Key Vault Secrets Users"
  type        = list(string)
  default     = []
}

variable "certificates_user_object_ids" {
  description = "Object IDs for Key Vault Certificates Users"
  type        = list(string)
  default     = []
}

variable "crypto_user_object_ids" {
  description = "Object IDs for Key Vault Crypto Users"
  type        = list(string)
  default     = []
}

# Monitoring
variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

# Private Endpoint
variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for Key Vault"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
