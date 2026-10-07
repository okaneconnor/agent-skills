# =============================================================================
# Virtual Machine Module
# Creates Azure VMs with configurable settings
# =============================================================================

# =============================================================================
# Network Interface
# =============================================================================

resource "azurerm_network_interface" "vm" {
  for_each = var.vms

  name                = "nic-${each.key}-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = each.value.private_ip_address != null ? "Static" : "Dynamic"
    private_ip_address            = each.value.private_ip_address
  }

  tags = merge(var.tags, {
    Module = "vm"
    VM     = each.key
  })
}

# =============================================================================
# Linux Virtual Machines
# =============================================================================

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = { for k, v in var.vms : k => v if v.os_type == "Linux" }

  name                            = "vm-${each.key}-${var.environment}-${var.location_short}-001"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = each.value.size
  admin_username                  = each.value.admin_username
  disable_password_authentication = true
  zone                            = each.value.zone

  network_interface_ids = [
    azurerm_network_interface.vm[each.key].id
  ]

  admin_ssh_key {
    username   = each.value.admin_username
    public_key = each.value.ssh_public_key
  }

  identity {
    type         = "UserAssigned"
    identity_ids = each.value.identity_ids != null ? each.value.identity_ids : []
  }

  os_disk {
    name                 = "osdisk-${each.key}-${var.environment}-${var.location_short}-001"
    caching              = "ReadWrite"
    storage_account_type = each.value.os_disk_type
    disk_size_gb         = each.value.os_disk_size_gb
  }

  source_image_reference {
    publisher = each.value.image.publisher
    offer     = each.value.image.offer
    sku       = each.value.image.sku
    version   = each.value.image.version
  }

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_uri
  }

  tags = merge(var.tags, {
    Module = "vm"
    VM     = each.key
  })

  lifecycle {
    ignore_changes = [
      admin_ssh_key,
    ]
  }
}

# =============================================================================
# Windows Virtual Machines
# =============================================================================

resource "azurerm_windows_virtual_machine" "vm" {
  for_each = { for k, v in var.vms : k => v if v.os_type == "Windows" }

  name                = "vm-${each.key}-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = each.value.size
  admin_username      = each.value.admin_username
  admin_password      = each.value.admin_password
  zone                = each.value.zone

  network_interface_ids = [
    azurerm_network_interface.vm[each.key].id
  ]

  identity {
    type         = "UserAssigned"
    identity_ids = each.value.identity_ids != null ? each.value.identity_ids : []
  }

  os_disk {
    name                 = "osdisk-${each.key}-${var.environment}-${var.location_short}-001"
    caching              = "ReadWrite"
    storage_account_type = each.value.os_disk_type
    disk_size_gb         = each.value.os_disk_size_gb
  }

  source_image_reference {
    publisher = each.value.image.publisher
    offer     = each.value.image.offer
    sku       = each.value.image.sku
    version   = each.value.image.version
  }

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_uri
  }

  tags = merge(var.tags, {
    Module = "vm"
    VM     = each.key
  })
}

# =============================================================================
# Data Disks
# =============================================================================

resource "azurerm_managed_disk" "data_disks" {
  for_each = { for item in local.data_disks_flat : "${item.vm_name}-${item.disk_name}" => item }

  name                 = "disk-${each.value.vm_name}-${each.value.disk_name}-${var.environment}-${var.location_short}-001"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = each.value.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = each.value.disk_size_gb
  zone                 = each.value.zone

  tags = merge(var.tags, {
    Module = "vm"
    VM     = each.value.vm_name
  })
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disks" {
  for_each = { for item in local.data_disks_flat : "${item.vm_name}-${item.disk_name}" => item }

  managed_disk_id    = azurerm_managed_disk.data_disks[each.key].id
  virtual_machine_id = each.value.os_type == "Linux" ? azurerm_linux_virtual_machine.vm[each.value.vm_name].id : azurerm_windows_virtual_machine.vm[each.value.vm_name].id
  lun                = each.value.lun
  caching            = each.value.caching
}

# =============================================================================
# Locals for Data Disk Processing
# =============================================================================

locals {
  data_disks_flat = flatten([
    for vm_name, vm in var.vms : [
      for disk_name, disk in coalesce(vm.data_disks, {}) : {
        vm_name              = vm_name
        disk_name            = disk_name
        disk_size_gb         = disk.disk_size_gb
        storage_account_type = disk.storage_account_type
        lun                  = disk.lun
        caching              = disk.caching
        zone                 = vm.zone
        os_type              = vm.os_type
      }
    ]
  ])
}
