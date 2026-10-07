# =============================================================================
# VNet Peering Module Variables
# =============================================================================

variable "hub_vnet_id" {
  description = "ID of the hub VNet"
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of the hub VNet"
  type        = string
}

variable "hub_resource_group_name" {
  description = "Resource group name of the hub VNet"
  type        = string
}

variable "spoke_vnet_id" {
  description = "ID of the spoke VNet"
  type        = string
}

variable "spoke_vnet_name" {
  description = "Name of the spoke VNet"
  type        = string
}

variable "spoke_resource_group_name" {
  description = "Resource group name of the spoke VNet"
  type        = string
}

variable "spoke_name" {
  description = "Name of the spoke (used for peering name)"
  type        = string
}

variable "allow_forwarded_traffic" {
  description = "Allow forwarded traffic between VNets"
  type        = bool
  default     = true
}

variable "allow_gateway_transit" {
  description = "Allow gateway transit from hub to spoke"
  type        = bool
  default     = true
}

variable "use_remote_gateways" {
  description = "Use hub's VPN/ExpressRoute gateway from spoke"
  type        = bool
  default     = false
}
