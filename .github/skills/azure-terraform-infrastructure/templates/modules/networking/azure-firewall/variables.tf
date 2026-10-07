# =============================================================================
# Azure Firewall Module Variables
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

variable "firewall_subnet_id" {
  description = "ID of the AzureFirewallSubnet"
  type        = string
}

variable "firewall_sku" {
  description = "SKU tier of the Firewall (Standard or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku)
    error_message = "Firewall SKU must be either 'Standard' or 'Premium'."
  }
}

variable "availability_zones" {
  description = "Availability zones for the Firewall"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "threat_intelligence_mode" {
  description = "Threat intelligence mode (Off, Alert, Deny)"
  type        = string
  default     = "Alert"

  validation {
    condition     = contains(["Off", "Alert", "Deny"], var.threat_intelligence_mode)
    error_message = "Threat intelligence mode must be 'Off', 'Alert', or 'Deny'."
  }
}

variable "dns_proxy_enabled" {
  description = "Enable DNS proxy on the Firewall"
  type        = bool
  default     = true
}

variable "dns_servers" {
  description = "Custom DNS servers for the Firewall"
  type        = list(string)
  default     = null
}

variable "intrusion_detection_mode" {
  description = "IDPS mode (Off, Alert, Deny) - Premium SKU only"
  type        = string
  default     = "Alert"

  validation {
    condition     = contains(["Off", "Alert", "Deny"], var.intrusion_detection_mode)
    error_message = "Intrusion detection mode must be 'Off', 'Alert', or 'Deny'."
  }
}

variable "network_rule_collections" {
  description = "Network rule collections for the Firewall"
  type = map(object({
    priority = number
    action   = string # Allow or Deny
    rules = map(object({
      protocols             = list(string)
      source_addresses      = list(string)
      destination_addresses = list(string)
      destination_ports     = list(string)
    }))
  }))
  default = {}
}

variable "application_rule_collections" {
  description = "Application rule collections for the Firewall"
  type = map(object({
    priority = number
    action   = string # Allow or Deny
    rules = map(object({
      source_addresses  = list(string)
      destination_fqdns = list(string)
      protocols = list(object({
        type = string # Http, Https
        port = number
      }))
    }))
  }))
  default = {}
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
