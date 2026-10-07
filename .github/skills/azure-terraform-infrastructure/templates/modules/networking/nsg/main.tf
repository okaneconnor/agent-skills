# =============================================================================
# Network Security Group Module
# Creates NSG with configurable rules
# =============================================================================

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.nsg_name}-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(var.tags, {
    Module = "nsg"
  })
}

# =============================================================================
# Security Rules
# =============================================================================

resource "azurerm_network_security_rule" "rules" {
  for_each = var.security_rules

  name                         = each.key
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = each.value.source_port_range
  destination_port_range       = each.value.destination_port_range
  source_port_ranges           = each.value.source_port_ranges
  destination_port_ranges      = each.value.destination_port_ranges
  source_address_prefix        = each.value.source_address_prefix
  destination_address_prefix   = each.value.destination_address_prefix
  source_address_prefixes      = each.value.source_address_prefixes
  destination_address_prefixes = each.value.destination_address_prefixes
  resource_group_name          = var.resource_group_name
  network_security_group_name  = azurerm_network_security_group.nsg.name
  description                  = each.value.description
}

# =============================================================================
# Subnet Association
# =============================================================================

resource "azurerm_subnet_network_security_group_association" "association" {
  for_each = var.subnet_ids

  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# =============================================================================
# NSG Flow Logs (Optional)
# =============================================================================

resource "azurerm_network_watcher_flow_log" "flow_log" {
  for_each = var.enable_flow_logs && var.network_watcher_name != null && var.storage_account_id != null ? { "flow_log" = true } : {}

  network_watcher_name      = var.network_watcher_name
  resource_group_name       = var.network_watcher_resource_group
  name                      = "fl-${var.nsg_name}-${var.environment}-${var.location_short}-001"
  network_security_group_id = azurerm_network_security_group.nsg.id
  storage_account_id        = var.storage_account_id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = var.flow_log_retention_days
  }

  dynamic "traffic_analytics" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []

    content {
      enabled               = true
      workspace_id          = var.log_analytics_workspace_id
      workspace_region      = var.location
      workspace_resource_id = var.log_analytics_workspace_resource_id
      interval_in_minutes   = 10
    }
  }

  tags = merge(var.tags, {
    Module = "nsg"
  })
}
