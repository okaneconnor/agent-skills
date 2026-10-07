# =============================================================================
# Azure Firewall Module
# Creates Azure Firewall with policy and rules
# =============================================================================

# =============================================================================
# Public IP for Firewall
# =============================================================================

resource "azurerm_public_ip" "firewall" {
  name                = "pip-fw-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = merge(var.tags, {
    Module = "azure-firewall"
  })
}

# =============================================================================
# Firewall Policy
# =============================================================================

resource "azurerm_firewall_policy" "policy" {
  name                     = "afwp-${var.environment}-${var.location_short}-001"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  sku                      = var.firewall_sku
  threat_intelligence_mode = var.threat_intelligence_mode

  dns {
    proxy_enabled = var.dns_proxy_enabled
    servers       = var.dns_servers
  }

  dynamic "intrusion_detection" {
    for_each = var.firewall_sku == "Premium" ? [1] : []

    content {
      mode = var.intrusion_detection_mode
    }
  }

  tags = merge(var.tags, {
    Module = "azure-firewall"
  })
}

# =============================================================================
# Firewall Policy Rule Collection Groups
# =============================================================================

resource "azurerm_firewall_policy_rule_collection_group" "network_rules" {
  name               = "rcg-network-rules"
  firewall_policy_id = azurerm_firewall_policy.policy.id
  priority           = 200

  dynamic "network_rule_collection" {
    for_each = var.network_rule_collections

    content {
      name     = network_rule_collection.key
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = network_rule_collection.value.rules

        content {
          name                  = rule.key
          protocols             = rule.value.protocols
          source_addresses      = rule.value.source_addresses
          destination_addresses = rule.value.destination_addresses
          destination_ports     = rule.value.destination_ports
        }
      }
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "application_rules" {
  name               = "rcg-application-rules"
  firewall_policy_id = azurerm_firewall_policy.policy.id
  priority           = 300

  dynamic "application_rule_collection" {
    for_each = var.application_rule_collections

    content {
      name     = application_rule_collection.key
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action

      dynamic "rule" {
        for_each = application_rule_collection.value.rules

        content {
          name              = rule.key
          source_addresses  = rule.value.source_addresses
          destination_fqdns = rule.value.destination_fqdns

          dynamic "protocols" {
            for_each = rule.value.protocols

            content {
              type = protocols.value.type
              port = protocols.value.port
            }
          }
        }
      }
    }
  }
}

# =============================================================================
# Azure Firewall
# =============================================================================

resource "azurerm_firewall" "firewall" {
  name                = "afw-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku
  firewall_policy_id  = azurerm_firewall_policy.policy.id
  zones               = var.availability_zones

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  tags = merge(var.tags, {
    Module = "azure-firewall"
  })
}

# =============================================================================
# Diagnostic Settings
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  for_each = var.log_analytics_workspace_id != null ? { "diag" = true } : {}

  name                       = "diag-firewall"
  target_resource_id         = azurerm_firewall.firewall.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  enabled_log {
    category = "AzureFirewallDnsProxy"
  }

  metric {
    category = "AllMetrics"
  }
}
