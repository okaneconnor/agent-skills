# =============================================================================
# Hub Virtual Network Module
# Creates the central hub VNet with Firewall, Bastion, and Gateway subnets
# =============================================================================

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]

  tags = merge(var.tags, {
    Module = "hub-vnet"
  })
}

# =============================================================================
# Subnets
# =============================================================================

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet" # Required name for Azure Firewall
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_prefixes.firewall]
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet" # Required name for VPN/ExpressRoute Gateway
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_prefixes.gateway]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet" # Required name for Azure Bastion
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_prefixes.bastion]
}

resource "azurerm_subnet" "management" {
  name                 = "snet-management-${var.environment}-${var.location_short}-001"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_prefixes.management]
}

# =============================================================================
# Azure Bastion
# =============================================================================

resource "azurerm_public_ip" "bastion" {
  for_each = var.enable_bastion ? { "bastion" = true } : {}

  name                = "pip-bastion-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(var.tags, {
    Module = "hub-vnet"
  })
}

resource "azurerm_bastion_host" "hub" {
  for_each = var.enable_bastion ? { "bastion" = true } : {}

  name                = "bas-hub-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.bastion_sku

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion["bastion"].id
  }

  tags = merge(var.tags, {
    Module = "hub-vnet"
  })
}

# =============================================================================
# Route Table for Spoke Traffic (through Firewall)
# =============================================================================

resource "azurerm_route_table" "hub" {
  name                          = "rt-hub-${var.environment}-${var.location_short}-001"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = false

  tags = merge(var.tags, {
    Module = "hub-vnet"
  })
}

resource "azurerm_route" "to_internet" {
  for_each = var.firewall_private_ip != null ? { "internet" = true } : {}

  name                   = "route-to-internet"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.hub.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_private_ip
}

resource "azurerm_subnet_route_table_association" "management" {
  subnet_id      = azurerm_subnet.management.id
  route_table_id = azurerm_route_table.hub.id
}
