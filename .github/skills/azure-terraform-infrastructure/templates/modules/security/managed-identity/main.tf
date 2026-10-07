# =============================================================================
# User-Assigned Managed Identity Module
# Creates managed identities for workload authentication
# =============================================================================

resource "azurerm_user_assigned_identity" "identity" {
  name                = "id-${var.identity_name}-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(var.tags, {
    Module = "managed-identity"
  })
}

# =============================================================================
# Role Assignments
# =============================================================================

resource "azurerm_role_assignment" "assignments" {
  for_each = var.role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

# =============================================================================
# Federated Identity Credentials (for Workload Identity)
# =============================================================================

resource "azurerm_federated_identity_credential" "credentials" {
  for_each = var.federated_identity_credentials

  name                = each.key
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.identity.id
  audience            = each.value.audience
  issuer              = each.value.issuer
  subject             = each.value.subject
}
