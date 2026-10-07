# =============================================================================
# Spoke Virtual Network Module
# Creates a spoke VNet with customizable subnets
# =============================================================================

resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${var.spoke_name}-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]

  tags = merge(var.tags, {
    Module    = "spoke-vnet"
    SpokeName = var.spoke_name
  })
}

# =============================================================================
# Dynamic Subnets
# =============================================================================

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                                          = each.value.name != null ? each.value.name : "snet-${each.key}-${var.environment}-${var.location_short}-001"
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.spoke.name
  address_prefixes                              = [each.value.address_prefix]
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []

    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}

# =============================================================================
# Route Table (for traffic through hub firewall)
# =============================================================================

resource "azurerm_route_table" "spoke" {
  for_each = var.create_route_table ? { "rt" = true } : {}

  name                          = "rt-${var.spoke_name}-${var.environment}-${var.location_short}-001"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = var.disable_bgp_route_propagation

  tags = merge(var.tags, {
    Module    = "spoke-vnet"
    SpokeName = var.spoke_name
  })
}

resource "azurerm_route" "to_internet" {
  for_each = var.create_route_table && var.firewall_private_ip != null ? { "internet" = true } : {}

  name                   = "route-to-internet"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.spoke["rt"].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_private_ip
}

resource "azurerm_route" "to_hub" {
  for_each = var.create_route_table && var.hub_address_space != null && var.firewall_private_ip != null ? { "hub" = true } : {}

  name                   = "route-to-hub"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.spoke["rt"].name
  address_prefix         = var.hub_address_space
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_private_ip
}

resource "azurerm_subnet_route_table_association" "subnets" {
  for_each = var.create_route_table ? { for k, v in var.subnets : k => v if v.associate_route_table } : {}

  subnet_id      = azurerm_subnet.subnets[each.key].id
  route_table_id = azurerm_route_table.spoke["rt"].id
}
