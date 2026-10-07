# =============================================================================
# Azure Key Vault Module
# Creates Key Vault with RBAC access model
# =============================================================================

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  name                          = "kv-${var.vault_name}-${var.environment}-${var.location_short}-001"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.sku_name
  soft_delete_retention_days    = var.soft_delete_retention_days
  purge_protection_enabled      = var.purge_protection_enabled
  enabled_for_disk_encryption   = var.enabled_for_disk_encryption
  enabled_for_deployment        = var.enabled_for_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization     = true # Always use RBAC

  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    default_action             = var.network_acls.default_action
    bypass                     = var.network_acls.bypass
    ip_rules                   = var.network_acls.ip_rules
    virtual_network_subnet_ids = var.network_acls.virtual_network_subnet_ids
  }

  tags = merge(var.tags, {
    Module = "key-vault"
  })
}

# =============================================================================
# RBAC Role Assignments
# =============================================================================

# Key Vault Administrator for specified principals
resource "azurerm_role_assignment" "administrators" {
  for_each = toset(var.administrator_object_ids)

  scope                = azurerm_key_vault.vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value
}

# Key Vault Secrets User for specified principals
resource "azurerm_role_assignment" "secrets_users" {
  for_each = toset(var.secrets_user_object_ids)

  scope                = azurerm_key_vault.vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

# Key Vault Certificates User for specified principals
resource "azurerm_role_assignment" "certificates_users" {
  for_each = toset(var.certificates_user_object_ids)

  scope                = azurerm_key_vault.vault.id
  role_definition_name = "Key Vault Certificate User"
  principal_id         = each.value
}

# Key Vault Crypto User for specified principals
resource "azurerm_role_assignment" "crypto_users" {
  for_each = toset(var.crypto_user_object_ids)

  scope                = azurerm_key_vault.vault.id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = each.value
}

# =============================================================================
# Diagnostic Settings
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "vault" {
  for_each = var.log_analytics_workspace_id != null ? { "diag" = true } : {}

  name                       = "diag-keyvault"
  target_resource_id         = azurerm_key_vault.vault.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
  }
}

# =============================================================================
# Private Endpoint (Optional)
# =============================================================================

resource "azurerm_private_endpoint" "vault" {
  for_each = var.private_endpoint_subnet_id != null ? { "pe" = true } : {}

  name                = "pe-${var.vault_name}-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = azurerm_key_vault.vault.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []

    content {
      name                 = "pdnszg-keyvault"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = merge(var.tags, {
    Module = "key-vault"
  })
}
