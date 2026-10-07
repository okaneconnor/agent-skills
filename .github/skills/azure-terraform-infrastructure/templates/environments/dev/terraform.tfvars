# =============================================================================
# Dev Environment - Variable Values
# =============================================================================

# Project Configuration
project_name   = "myproject"
location       = "eastus"
location_short = "eus"

# Network CIDRs
hub_vnet_cidr  = "10.0.0.0/16"
aks_spoke_cidr = "10.1.0.0/16"
vm_spoke_cidr  = "10.2.0.0/16"

# Feature Flags (cost-optimized for dev)
enable_bastion  = true
enable_firewall = false # Enable if you need egress filtering

# Access Control
# Add your Azure AD object IDs here
key_vault_admin_object_ids = []
aks_admin_group_object_ids = []
