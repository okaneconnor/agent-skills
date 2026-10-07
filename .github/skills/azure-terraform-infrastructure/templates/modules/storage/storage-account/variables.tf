# =============================================================================
# Storage Account Module Variables
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

variable "storage_name" {
  description = "Name suffix for the storage account (lowercase, no special chars)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.storage_name))
    error_message = "Storage name must be lowercase alphanumeric only."
  }
}

variable "account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  type        = string
  default     = "GRS"
}

variable "account_kind" {
  description = "Storage account kind"
  type        = string
  default     = "StorageV2"
}

variable "access_tier" {
  description = "Access tier (Hot or Cool)"
  type        = string
  default     = "Hot"
}

variable "shared_access_key_enabled" {
  description = "Enable shared access key authentication"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "infrastructure_encryption_enabled" {
  description = "Enable infrastructure encryption"
  type        = bool
  default     = false
}

# Blob Properties
variable "enable_versioning" {
  description = "Enable blob versioning"
  type        = bool
  default     = true
}

variable "blob_soft_delete_retention_days" {
  description = "Blob soft delete retention days (0 to disable)"
  type        = number
  default     = 7
}

variable "container_soft_delete_retention_days" {
  description = "Container soft delete retention days (0 to disable)"
  type        = number
  default     = 7
}

variable "cors_rules" {
  description = "CORS rules for blob storage"
  type = list(object({
    allowed_headers    = list(string)
    allowed_methods    = list(string)
    allowed_origins    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  }))
  default = []
}

# Network Rules
variable "network_rules" {
  description = "Network rules for the storage account"
  type = object({
    default_action             = string
    bypass                     = list(string)
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = {
    default_action             = "Allow"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}

# Resources
variable "containers" {
  description = "Blob containers to create"
  type = map(object({
    access_type = optional(string, "private")
  }))
  default = {}
}

variable "file_shares" {
  description = "File shares to create"
  type = map(object({
    quota       = number
    access_tier = optional(string, "TransactionOptimized")
  }))
  default = {}
}

variable "queues" {
  description = "Storage queues to create"
  type        = map(object({}))
  default     = {}
}

variable "tables" {
  description = "Storage tables to create"
  type        = map(object({}))
  default     = {}
}

# Lifecycle Management
variable "lifecycle_rules" {
  description = "Lifecycle management rules"
  type = map(object({
    enabled      = optional(bool, true)
    blob_types   = optional(list(string), ["blockBlob"])
    prefix_match = optional(list(string), [])
    base_blob_actions = optional(object({
      tier_to_cool_after_days    = optional(number)
      tier_to_archive_after_days = optional(number)
      delete_after_days          = optional(number)
    }))
    snapshot_actions = optional(object({
      delete_after_days = optional(number)
    }))
    version_actions = optional(object({
      delete_after_days = optional(number)
    }))
  }))
  default = {}
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

variable "enable_blob_private_endpoint" {
  description = "Enable private endpoint for blob storage"
  type        = bool
  default     = true
}

variable "blob_private_dns_zone_id" {
  description = "Private DNS zone ID for blob storage"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
