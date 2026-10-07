# =============================================================================
# Managed Identity Module Variables
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

variable "identity_name" {
  description = "Name suffix for the managed identity"
  type        = string
}

variable "role_assignments" {
  description = "Role assignments for the managed identity"
  type = map(object({
    scope                = string
    role_definition_name = string
  }))
  default = {}
}

variable "federated_identity_credentials" {
  description = "Federated identity credentials for workload identity"
  type = map(object({
    audience = list(string)
    issuer   = string
    subject  = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
