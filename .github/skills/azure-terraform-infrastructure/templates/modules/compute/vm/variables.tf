# =============================================================================
# VM Module Variables
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

variable "subnet_id" {
  description = "ID of the subnet for VMs"
  type        = string
}

variable "vms" {
  description = "Map of VMs to create"
  type = map(object({
    size               = string
    os_type            = string # Linux or Windows
    admin_username     = string
    admin_password     = optional(string) # Required for Windows
    ssh_public_key     = optional(string) # Required for Linux
    zone               = optional(string)
    private_ip_address = optional(string)
    os_disk_size_gb    = optional(number, 128)
    os_disk_type       = optional(string, "Premium_LRS")
    identity_ids       = optional(list(string))
    image = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    data_disks = optional(map(object({
      disk_size_gb         = number
      storage_account_type = optional(string, "Premium_LRS")
      lun                  = number
      caching              = optional(string, "ReadWrite")
    })))
  }))
  default = {}
}

variable "boot_diagnostics_storage_uri" {
  description = "Storage account URI for boot diagnostics"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
