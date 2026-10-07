# =============================================================================
# Spoke VNet Module Variables
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
  description = "Short name for the Azure region (e.g., eus for eastus)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "spoke_name" {
  description = "Name of the spoke (e.g., aks, app, data)"
  type        = string
}

variable "address_space" {
  description = "Address space for the spoke VNet"
  type        = string
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    name                                          = optional(string)
    address_prefix                                = string
    private_endpoint_network_policies             = optional(string, "Disabled")
    private_link_service_network_policies_enabled = optional(bool, false)
    associate_route_table                         = optional(bool, true)
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = list(string)
    }))
  }))
}

variable "create_route_table" {
  description = "Whether to create a route table for the spoke"
  type        = bool
  default     = true
}

variable "disable_bgp_route_propagation" {
  description = "Whether to disable BGP route propagation"
  type        = bool
  default     = false
}

variable "firewall_private_ip" {
  description = "Private IP of Azure Firewall for routing"
  type        = string
  default     = null
}

variable "hub_address_space" {
  description = "Address space of the hub VNet (for routing)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
