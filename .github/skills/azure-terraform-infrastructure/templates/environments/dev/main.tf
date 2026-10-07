# =============================================================================
# Dev Environment - Main Configuration
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false # Allow deletion in dev
    }
  }
}

provider "azuread" {}

# =============================================================================
# Local Values
# =============================================================================

locals {
  environment    = "dev"
  location       = var.location
  location_short = var.location_short

  common_tags = {
    Environment = local.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }
}

# =============================================================================
# Resource Groups
# =============================================================================

resource "azurerm_resource_group" "network_hub" {
  name     = "rg-network-hub-${local.environment}-${local.location_short}-001"
  location = local.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "network_spoke" {
  name     = "rg-network-spoke-${local.environment}-${local.location_short}-001"
  location = local.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "compute" {
  name     = "rg-compute-${local.environment}-${local.location_short}-001"
  location = local.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "security" {
  name     = "rg-security-${local.environment}-${local.location_short}-001"
  location = local.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "monitoring" {
  name     = "rg-monitoring-${local.environment}-${local.location_short}-001"
  location = local.location
  tags     = local.common_tags
}

# =============================================================================
# Monitoring (Deploy First)
# =============================================================================

module "log_analytics" {
  source = "../../modules/monitoring/log-analytics"

  resource_group_name = azurerm_resource_group.monitoring.name
  location            = local.location
  location_short      = local.location_short
  environment         = local.environment
  workspace_name      = var.project_name
  retention_in_days   = 30 # Shorter retention for dev

  solutions = [
    "ContainerInsights",
    "VMInsights"
  ]

  tags = local.common_tags
}

# =============================================================================
# Hub Network
# =============================================================================

module "hub_vnet" {
  source = "../../modules/networking/hub-vnet"

  resource_group_name = azurerm_resource_group.network_hub.name
  location            = local.location
  location_short      = local.location_short
  environment         = local.environment
  address_space       = var.hub_vnet_cidr

  subnet_prefixes = {
    firewall   = cidrsubnet(var.hub_vnet_cidr, 8, 1)
    gateway    = cidrsubnet(var.hub_vnet_cidr, 8, 2)
    bastion    = cidrsubnet(var.hub_vnet_cidr, 11, 24) # /27
    management = cidrsubnet(var.hub_vnet_cidr, 8, 4)
  }

  enable_bastion      = var.enable_bastion
  bastion_sku         = "Basic" # Basic for dev
  firewall_private_ip = var.enable_firewall ? module.azure_firewall[0].firewall_private_ip : null

  tags = local.common_tags
}

# =============================================================================
# Azure Firewall (Optional for Dev)
# =============================================================================

module "azure_firewall" {
  source = "../../modules/networking/azure-firewall"

  for_each = var.enable_firewall ? { "firewall" = true } : {}

  resource_group_name = azurerm_resource_group.network_hub.name
  location            = local.location
  location_short      = local.location_short
  environment         = local.environment
  firewall_subnet_id  = module.hub_vnet.firewall_subnet_id
  firewall_sku        = "Standard"
  availability_zones  = [] # No zones for dev cost savings

  log_analytics_workspace_id = module.log_analytics.workspace_id

  # Basic rules for dev
  network_rule_collections = {
    allow-internal = {
      priority = 100
      action   = "Allow"
      rules = {
        allow-spoke-to-spoke = {
          protocols             = ["Any"]
          source_addresses      = [var.aks_spoke_cidr, var.vm_spoke_cidr]
          destination_addresses = [var.aks_spoke_cidr, var.vm_spoke_cidr]
          destination_ports     = ["*"]
        }
      }
    }
  }

  application_rule_collections = {
    allow-internet = {
      priority = 200
      action   = "Allow"
      rules = {
        allow-all-http = {
          source_addresses  = ["*"]
          destination_fqdns = ["*"]
          protocols = [
            { type = "Http", port = 80 },
            { type = "Https", port = 443 }
          ]
        }
      }
    }
  }

  tags = local.common_tags
}

# =============================================================================
# AKS Spoke Network
# =============================================================================

module "aks_spoke_vnet" {
  source = "../../modules/networking/spoke-vnet"

  resource_group_name = azurerm_resource_group.network_spoke.name
  location            = local.location
  location_short      = local.location_short
  environment         = local.environment
  spoke_name          = "aks"
  address_space       = var.aks_spoke_cidr

  subnets = {
    aks-nodes = {
      address_prefix        = cidrsubnet(var.aks_spoke_cidr, 2, 0) # /18 for nodes
      associate_route_table = var.enable_firewall
    }
    aks-internal-lb = {
      address_prefix        = cidrsubnet(var.aks_spoke_cidr, 8, 64)
      associate_route_table = false
    }
    private-endpoints = {
      address_prefix                    = cidrsubnet(var.aks_spoke_cidr, 8, 65)
      private_endpoint_network_policies = "Enabled"
      associate_route_table             = false
    }
  }

  create_route_table  = var.enable_firewall
  firewall_private_ip = var.enable_firewall ? module.azure_firewall["firewall"].firewall_private_ip : null
  hub_address_space   = var.hub_vnet_cidr

  tags = local.common_tags
}

# =============================================================================
# VNet Peering
# =============================================================================

module "aks_spoke_peering" {
  source = "../../modules/networking/vnet-peering"

  hub_vnet_id             = module.hub_vnet.vnet_id
  hub_vnet_name           = module.hub_vnet.vnet_name
  hub_resource_group_name = azurerm_resource_group.network_hub.name

  spoke_vnet_id             = module.aks_spoke_vnet.vnet_id
  spoke_vnet_name           = module.aks_spoke_vnet.vnet_name
  spoke_resource_group_name = azurerm_resource_group.network_spoke.name
  spoke_name                = "aks"

  allow_gateway_transit = false # No gateway in dev
  use_remote_gateways   = false
}

# =============================================================================
# Key Vault
# =============================================================================

module "key_vault" {
  source = "../../modules/security/key-vault"

  resource_group_name = azurerm_resource_group.security.name
  location            = local.location
  location_short      = local.location_short
  environment         = local.environment
  vault_name          = var.project_name

  sku_name                 = "standard"
  purge_protection_enabled = false # Allow purge in dev

  administrator_object_ids = var.key_vault_admin_object_ids

  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags
}

# =============================================================================
# AKS Cluster
# =============================================================================

module "aks" {
  source = "../../modules/compute/aks"

  resource_group_name = azurerm_resource_group.compute.name
  location            = local.location
  location_short      = local.location_short
  environment         = local.environment
  cluster_name        = var.project_name

  subnet_id          = module.aks_spoke_vnet.subnet_ids["aks-nodes"]
  availability_zones = [] # No zones for dev cost savings

  system_node_pool = {
    vm_size             = "Standard_D2s_v5" # Smaller for dev
    node_count          = 1
    min_count           = 1
    max_count           = 3
    enable_auto_scaling = true
    max_pods            = 30
    os_disk_size_gb     = 64
    os_disk_type        = "Managed"
  }

  node_pools = {
    workload = {
      vm_size             = "Standard_D4s_v5"
      node_count          = 1
      min_count           = 1
      max_count           = 5
      enable_auto_scaling = true
      max_pods            = 30
      os_disk_size_gb     = 128
      mode                = "User"
      node_labels = {
        "workload" = "general"
      }
    }
  }

  # Network
  network_plugin      = "azure"
  network_plugin_mode = "overlay"
  network_policy      = "azure"
  outbound_type       = var.enable_firewall ? "userDefinedRouting" : "loadBalancer"

  # Features
  enable_azure_ad_integration       = true
  azure_rbac_enabled                = true
  admin_group_object_ids            = var.aks_admin_group_object_ids
  enable_key_vault_secrets_provider = true
  enable_azure_policy               = false # Disabled for dev
  enable_workload_identity          = true

  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags

  depends_on = [module.aks_spoke_peering]
}

# =============================================================================
# Storage Account
# =============================================================================

module "storage" {
  source = "../../modules/storage/storage-account"

  resource_group_name = azurerm_resource_group.security.name
  location            = local.location
  location_short      = local.location_short
  environment         = local.environment
  storage_name        = replace(var.project_name, "-", "")

  account_replication_type = "LRS" # Local redundancy for dev

  containers = {
    data = {
      access_type = "private"
    }
    backups = {
      access_type = "private"
    }
  }

  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags
}
