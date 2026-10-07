# =============================================================================
# Azure Kubernetes Service (AKS) Module
# Creates an AKS cluster with configurable node pools
# =============================================================================

# =============================================================================
# User-Assigned Managed Identity for AKS
# =============================================================================

resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-aks-${var.cluster_name}-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(var.tags, {
    Module = "aks"
  })
}

# =============================================================================
# AKS Cluster
# =============================================================================

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.cluster_name}-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-${var.cluster_name}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  # System node pool (required)
  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_pool.vm_size
    node_count                   = var.system_node_pool.node_count
    min_count                    = var.system_node_pool.enable_auto_scaling ? var.system_node_pool.min_count : null
    max_count                    = var.system_node_pool.enable_auto_scaling ? var.system_node_pool.max_count : null
    enable_auto_scaling          = var.system_node_pool.enable_auto_scaling
    vnet_subnet_id               = var.subnet_id
    max_pods                     = var.system_node_pool.max_pods
    os_disk_size_gb              = var.system_node_pool.os_disk_size_gb
    os_disk_type                 = var.system_node_pool.os_disk_type
    temporary_name_for_rotation  = "systemtemp"
    only_critical_addons_enabled = true
    zones                        = var.availability_zones

    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }
  }

  # Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Network configuration
  network_profile {
    network_plugin      = var.network_plugin
    network_plugin_mode = var.network_plugin == "azure" ? var.network_plugin_mode : null
    network_policy      = var.network_policy
    dns_service_ip      = var.dns_service_ip
    service_cidr        = var.service_cidr
    outbound_type       = var.outbound_type
    load_balancer_sku   = "standard"
  }

  # Azure AD integration
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_azure_ad_integration ? [1] : []

    content {
      azure_rbac_enabled     = var.azure_rbac_enabled
      admin_group_object_ids = var.admin_group_object_ids
    }
  }

  # Key Vault Secrets Provider
  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_key_vault_secrets_provider ? [1] : []

    content {
      secret_rotation_enabled  = true
      secret_rotation_interval = "2m"
    }
  }

  # Azure Policy
  azure_policy_enabled = var.enable_azure_policy

  # Workload identity
  workload_identity_enabled = var.enable_workload_identity
  oidc_issuer_enabled       = var.enable_workload_identity

  # Monitoring
  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []

    content {
      log_analytics_workspace_id      = var.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = true
    }
  }

  # Maintenance window
  dynamic "maintenance_window_auto_upgrade" {
    for_each = var.maintenance_window != null ? [1] : []

    content {
      frequency   = var.maintenance_window.frequency
      interval    = var.maintenance_window.interval
      duration    = var.maintenance_window.duration
      day_of_week = var.maintenance_window.day_of_week
      start_time  = var.maintenance_window.start_time
      utc_offset  = var.maintenance_window.utc_offset
    }
  }

  automatic_upgrade_channel = var.automatic_upgrade_channel

  # Private cluster
  private_cluster_enabled             = var.private_cluster_enabled
  private_cluster_public_fqdn_enabled = var.private_cluster_public_fqdn_enabled
  private_dns_zone_id                 = var.private_dns_zone_id

  tags = merge(var.tags, {
    Module = "aks"
  })

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version,
    ]
  }
}

# =============================================================================
# Additional Node Pools
# =============================================================================

resource "azurerm_kubernetes_cluster_node_pool" "node_pools" {
  for_each = var.node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  min_count             = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count             = each.value.enable_auto_scaling ? each.value.max_count : null
  enable_auto_scaling   = each.value.enable_auto_scaling
  vnet_subnet_id        = var.subnet_id
  max_pods              = each.value.max_pods
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  os_type               = each.value.os_type
  mode                  = each.value.mode
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
  zones                 = var.availability_zones
  priority              = each.value.priority
  eviction_policy       = each.value.priority == "Spot" ? "Delete" : null
  spot_max_price        = each.value.spot_max_price

  upgrade_settings {
    max_surge                     = "10%"
    drain_timeout_in_minutes      = 0
    node_soak_duration_in_minutes = 0
  }

  tags = merge(var.tags, {
    Module   = "aks"
    NodePool = each.key
  })

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }
}

# =============================================================================
# Role Assignments
# =============================================================================

# AKS identity needs Network Contributor on the subnet
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# AKS identity needs Contributor on the resource group for load balancers
resource "azurerm_role_assignment" "aks_contributor" {
  scope                = var.node_resource_group_id != null ? var.node_resource_group_id : "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_kubernetes_cluster.aks.node_resource_group}"
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Data source for current subscription
data "azurerm_client_config" "current" {}
