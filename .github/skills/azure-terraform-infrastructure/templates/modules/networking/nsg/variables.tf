# =============================================================================
# NSG Module Variables
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

variable "nsg_name" {
  description = "Name suffix for the NSG"
  type        = string
}

variable "security_rules" {
  description = "Map of security rules to create"
  type = map(object({
    priority                     = number
    direction                    = string # Inbound or Outbound
    access                       = string # Allow or Deny
    protocol                     = string # Tcp, Udp, Icmp, Esp, Ah, *
    source_port_range            = optional(string)
    destination_port_range       = optional(string)
    source_port_ranges           = optional(list(string))
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    destination_address_prefix   = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefixes = optional(list(string))
    description                  = optional(string)
  }))
  default = {}
}

variable "subnet_ids" {
  description = "Map of subnet IDs to associate with this NSG"
  type        = map(string)
  default     = {}
}

variable "enable_flow_logs" {
  description = "Whether to enable NSG flow logs"
  type        = bool
  default     = false
}

variable "network_watcher_name" {
  description = "Name of the Network Watcher (required for flow logs)"
  type        = string
  default     = null
}

variable "network_watcher_resource_group" {
  description = "Resource group of the Network Watcher"
  type        = string
  default     = null
}

variable "storage_account_id" {
  description = "Storage account ID for flow logs"
  type        = string
  default     = null
}

variable "flow_log_retention_days" {
  description = "Retention days for flow logs"
  type        = number
  default     = 30
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for Traffic Analytics"
  type        = string
  default     = null
}

variable "log_analytics_workspace_resource_id" {
  description = "Log Analytics workspace resource ID for Traffic Analytics"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
