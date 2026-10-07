# =============================================================================
# Production Environment - Variable Values
# =============================================================================

project_name   = "myproject"
location       = "eastus"
location_short = "eus"

# Network CIDRs (production range)
hub_vnet_cidr  = "10.20.0.0/16"
aks_spoke_cidr = "10.21.0.0/16"
vm_spoke_cidr  = "10.22.0.0/16"

# Feature Flags (full security enabled)
enable_bastion         = true
enable_private_cluster = true

# Access Control
key_vault_admin_object_ids = []
aks_admin_group_object_ids = []

# Network allowed IPs (add your trusted IPs)
allowed_ip_ranges = []

# Compliance tags
cost_center      = "Engineering"
compliance_level = "SOC2"
