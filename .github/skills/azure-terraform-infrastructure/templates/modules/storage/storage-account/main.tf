# =============================================================================
# Storage Account Module
# Creates Azure Storage Account with security best practices
# =============================================================================

resource "azurerm_storage_account" "storage" {
  name                          = "st${var.storage_name}${var.environment}${var.location_short}001"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  account_tier                  = var.account_tier
  account_replication_type      = var.account_replication_type
  account_kind                  = var.account_kind
  access_tier                   = var.access_tier
  min_tls_version               = "TLS1_2"
  https_traffic_only_enabled    = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled     = var.shared_access_key_enabled
  public_network_access_enabled = var.public_network_access_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled

  # Blob properties
  blob_properties {
    versioning_enabled = var.enable_versioning

    dynamic "delete_retention_policy" {
      for_each = var.blob_soft_delete_retention_days > 0 ? [1] : []

      content {
        days = var.blob_soft_delete_retention_days
      }
    }

    dynamic "container_delete_retention_policy" {
      for_each = var.container_soft_delete_retention_days > 0 ? [1] : []

      content {
        days = var.container_soft_delete_retention_days
      }
    }

    dynamic "cors_rule" {
      for_each = var.cors_rules

      content {
        allowed_headers    = cors_rule.value.allowed_headers
        allowed_methods    = cors_rule.value.allowed_methods
        allowed_origins    = cors_rule.value.allowed_origins
        exposed_headers    = cors_rule.value.exposed_headers
        max_age_in_seconds = cors_rule.value.max_age_in_seconds
      }
    }
  }

  # Network rules
  network_rules {
    default_action             = var.network_rules.default_action
    bypass                     = var.network_rules.bypass
    ip_rules                   = var.network_rules.ip_rules
    virtual_network_subnet_ids = var.network_rules.virtual_network_subnet_ids
  }

  # Identity (for RBAC)
  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    Module = "storage-account"
  })
}

# =============================================================================
# Blob Containers
# =============================================================================

resource "azurerm_storage_container" "containers" {
  for_each = var.containers

  name                  = each.key
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = each.value.access_type
}

# =============================================================================
# File Shares
# =============================================================================

resource "azurerm_storage_share" "shares" {
  for_each = var.file_shares

  name                 = each.key
  storage_account_name = azurerm_storage_account.storage.name
  quota                = each.value.quota
  access_tier          = each.value.access_tier
}

# =============================================================================
# Queues
# =============================================================================

resource "azurerm_storage_queue" "queues" {
  for_each = var.queues

  name                 = each.key
  storage_account_name = azurerm_storage_account.storage.name
}

# =============================================================================
# Tables
# =============================================================================

resource "azurerm_storage_table" "tables" {
  for_each = var.tables

  name                 = each.key
  storage_account_name = azurerm_storage_account.storage.name
}

# =============================================================================
# Lifecycle Management Policy
# =============================================================================

resource "azurerm_storage_management_policy" "lifecycle" {
  for_each = length(var.lifecycle_rules) > 0 ? { "policy" = true } : {}

  storage_account_id = azurerm_storage_account.storage.id

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      name    = rule.key
      enabled = rule.value.enabled

      filters {
        blob_types   = rule.value.blob_types
        prefix_match = rule.value.prefix_match
      }

      actions {
        dynamic "base_blob" {
          for_each = rule.value.base_blob_actions != null ? [1] : []

          content {
            tier_to_cool_after_days_since_modification_greater_than    = rule.value.base_blob_actions.tier_to_cool_after_days
            tier_to_archive_after_days_since_modification_greater_than = rule.value.base_blob_actions.tier_to_archive_after_days
            delete_after_days_since_modification_greater_than          = rule.value.base_blob_actions.delete_after_days
          }
        }

        dynamic "snapshot" {
          for_each = rule.value.snapshot_actions != null ? [1] : []

          content {
            delete_after_days_since_creation_greater_than = rule.value.snapshot_actions.delete_after_days
          }
        }

        dynamic "version" {
          for_each = rule.value.version_actions != null ? [1] : []

          content {
            delete_after_days_since_creation = rule.value.version_actions.delete_after_days
          }
        }
      }
    }
  }
}

# =============================================================================
# Diagnostic Settings
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "storage" {
  for_each = var.log_analytics_workspace_id != null ? { "diag" = true } : {}

  name                       = "diag-storage"
  target_resource_id         = azurerm_storage_account.storage.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "Transaction"
  }

  metric {
    category = "Capacity"
  }
}

# =============================================================================
# Private Endpoint
# =============================================================================

resource "azurerm_private_endpoint" "blob" {
  for_each = var.private_endpoint_subnet_id != null && var.enable_blob_private_endpoint ? { "pe" = true } : {}

  name                = "pe-${var.storage_name}-blob-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.blob_private_dns_zone_id != null ? [1] : []

    content {
      name                 = "pdnszg-blob"
      private_dns_zone_ids = [var.blob_private_dns_zone_id]
    }
  }

  tags = merge(var.tags, {
    Module = "storage-account"
  })
}
