# =============================================================================
# Staging Environment - Variable Values
# =============================================================================

project_name   = "myproject"
location       = "eastus"
location_short = "eus"

# Network CIDRs (different from dev to avoid conflicts)
hub_vnet_cidr  = "10.10.0.0/16"
aks_spoke_cidr = "10.11.0.0/16"
vm_spoke_cidr  = "10.12.0.0/16"

# Feature Flags (production-like settings)
enable_bastion  = true
enable_firewall = true

# Access Control
key_vault_admin_object_ids = []
aks_admin_group_object_ids = []
