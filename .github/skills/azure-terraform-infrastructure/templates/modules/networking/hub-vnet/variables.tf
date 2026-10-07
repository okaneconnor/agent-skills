# =============================================================================
# Hub VNet Module Variables
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

variable "address_space" {
  description = "Address space for the hub VNet (e.g., 10.0.0.0/16)"
  type        = string
}

variable "subnet_prefixes" {
  description = "Subnet address prefixes"
  type = object({
    firewall   = string # Must be /24 or larger
    gateway    = string # Must be /27 or larger
    bastion    = string # Must be /27 or larger
    management = string
  })
  default = {
    firewall   = "10.0.1.0/24"
    gateway    = "10.0.2.0/24"
    bastion    = "10.0.3.0/27"
    management = "10.0.4.0/24"
  }
}

variable "enable_bastion" {
  description = "Whether to deploy Azure Bastion"
  type        = bool
  default     = true
}

variable "bastion_sku" {
  description = "SKU for Azure Bastion (Basic or Standard)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.bastion_sku)
    error_message = "Bastion SKU must be either 'Basic' or 'Standard'."
  }
}

variable "firewall_private_ip" {
  description = "Private IP of Azure Firewall (for route table). Set to null if no firewall."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
