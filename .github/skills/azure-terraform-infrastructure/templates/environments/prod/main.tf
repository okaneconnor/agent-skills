# =============================================================================
# Production Environment - Main Configuration
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
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azuread" {}

# =============================================================================
# Local Values
# =============================================================================

locals {
  environment    = "prod"
  location       = var.location
  location_short = var.location_short

  common_tags = {
    Environment = local.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    CostCenter  = var.cost_center
    Compliance  = var.compliance_level
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
# Monitoring
# =============================================================================

module "log_analytics" {
  source = "../../modules/monitoring/log-analytics"

  resource_group_name = azurerm_resource_group.monitoring.name
  location            = local.location
  location_short      = local.location_short
  environment         = local.environment
  workspace_name      = var.project_name
  retention_in_days   = 90 # Long retention for production

  solutions = [
    "ContainerInsights",
    "VMInsights",
    "SecurityInsights",
    "AzureActivity"
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
    bastion    = cidrsubnet(var.hub_vnet_cidr, 11, 24)
    management = cidrsubnet(var.hub_vnet_cidr, 8, 4)
  }

  enable_bastion      = var.enable_bastion
  bastion_sku         = "Standard"
  firewall_private_ip = module.azure_firewall["firewall"].firewall_private_ip

  tags = local.common_tags
}

# =============================================================================
# Azure Firewall (Required in Production)
# =============================================================================

module "azure_firewall" {
  source = "../../modules/networking/azure-firewall"

  for_each = { "firewall" = true } # Always enabled in prod

  resource_group_name = azurerm_resource_group.network_hub.name
  location            = local.location
  location_short      = local.location_short
  environment         = local.environment
  firewall_subnet_id  = module.hub_vnet.firewall_subnet_id
  firewall_sku        = "Premium" # Premium for production
  availability_zones  = ["1", "2", "3"]

  threat_intelligence_mode = "Deny"
  intrusion_detection_mode = "Alert"

  log_analytics_workspace_id = module.log_analytics.workspace_id

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
    allow-dns = {
      priority = 110
      action   = "Allow"
      rules = {
        allow-dns = {
          protocols             = ["UDP"]
          source_addresses      = ["*"]
          destination_addresses = ["168.63.129.16"]
          destination_ports     = ["53"]
        }
      }
    }
  }

  application_rule_collections = {
    allow-azure-services = {
      priority = 200
      action   = "Allow"
      rules = {
        allow-azure = {
          source_addresses  = ["*"]
          destination_fqdns = ["*.azure.com", "*.microsoft.com", "*.windows.net", "*.azurecr.io"]
          protocols = [
            { type = "Https", port = 443 }
          ]
        }
      }
    }
    allow-aks-required = {
      priority = 210
      action   = "Allow"
      rules = {
        allow-aks-fqdns = {
          source_addresses = [var.aks_spoke_cidr]
          destination_fqdns = [
            "*.hcp.${var.location}.azmk8s.io",
            "mcr.microsoft.com",
            "*.data.mcr.microsoft.com",
            "management.azure.com",
            "login.microsoftonline.com",
            "packages.microsoft.com",
            "acs-mirror.azureedge.net"
          ]
          protocols = [
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
      address_prefix        = cidrsubnet(var.aks_spoke_cidr, 2, 0)
      associate_route_table = true
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

  create_route_table  = true
  firewall_private_ip = module.azure_firewall["firewall"].firewall_private_ip
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

  allow_gateway_transit = true
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

  sku_name                 = "premium" # Premium for production (HSM support)
  purge_protection_enabled = true

  # Restrict network access in production
  public_network_access_enabled = false
  network_acls = {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = var.allowed_ip_ranges
    virtual_network_subnet_ids = [module.aks_spoke_vnet.subnet_ids["aks-nodes"]]
  }

  administrator_object_ids = var.key_vault_admin_object_ids

  private_endpoint_subnet_id = module.aks_spoke_vnet.subnet_ids["private-endpoints"]

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
  availability_zones = ["1", "2", "3"]

  system_node_pool = {
    vm_size             = "Standard_D4s_v5"
    node_count          = 3
    min_count           = 3
    max_count           = 6
    enable_auto_scaling = true
    max_pods            = 30
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
  }

  node_pools = {
    workload = {
      vm_size             = "Standard_D8s_v5"
      node_count          = 3
      min_count           = 3
      max_count           = 20
      enable_auto_scaling = true
      max_pods            = 30
      os_disk_size_gb     = 256
      mode                = "User"
      node_labels = {
        "workload" = "general"
      }
    }
  }

  network_plugin      = "azure"
  network_plugin_mode = "overlay"
  network_policy      = "azure"
  outbound_type       = "userDefinedRouting"

  # Private cluster for production
  private_cluster_enabled             = var.enable_private_cluster
  private_cluster_public_fqdn_enabled = false

  enable_azure_ad_integration       = true
  azure_rbac_enabled                = true
  admin_group_object_ids            = var.aks_admin_group_object_ids
  enable_key_vault_secrets_provider = true
  enable_azure_policy               = true
  enable_workload_identity          = true

  automatic_upgrade_channel = "patch"
  maintenance_window = {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "02:00"
    utc_offset  = "+00:00"
  }

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

  account_replication_type          = "GZRS" # Geo-zone redundancy for production
  infrastructure_encryption_enabled = true

  # Restrict network access
  public_network_access_enabled = false
  network_rules = {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = var.allowed_ip_ranges
    virtual_network_subnet_ids = [module.aks_spoke_vnet.subnet_ids["aks-nodes"]]
  }

  containers = {
    data = {
      access_type = "private"
    }
    backups = {
      access_type = "private"
    }
    logs = {
      access_type = "private"
    }
  }

  lifecycle_rules = {
    archive-old-data = {
      blob_types   = ["blockBlob"]
      prefix_match = ["data/"]
      base_blob_actions = {
        tier_to_cool_after_days    = 30
        tier_to_archive_after_days = 90
        delete_after_days          = 365
      }
    }
  }

  private_endpoint_subnet_id = module.aks_spoke_vnet.subnet_ids["private-endpoints"]

  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags
}
