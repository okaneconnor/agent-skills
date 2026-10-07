# Azure Terraform Infrastructure Reference

## Module Reference

### networking/hub-vnet

Creates the central hub VNet with Azure Firewall, Bastion, and Gateway subnets.

**Inputs:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| resource_group_name | string | yes | Resource group name |
| location | string | yes | Azure region |
| location_short | string | yes | Short region name (e.g., eus) |
| environment | string | yes | Environment (dev/staging/prod) |
| address_space | string | yes | VNet CIDR (e.g., 10.0.0.0/16) |
| subnet_prefixes | object | no | Custom subnet CIDRs |
| enable_bastion | bool | no | Deploy Azure Bastion (default: true) |
| bastion_sku | string | no | Basic or Standard (default: Standard) |
| firewall_private_ip | string | no | Firewall IP for routing |

**Outputs:**
- `vnet_id` - Hub VNet resource ID
- `vnet_name` - Hub VNet name
- `firewall_subnet_id` - AzureFirewallSubnet ID
- `gateway_subnet_id` - GatewaySubnet ID
- `bastion_subnet_id` - AzureBastionSubnet ID
- `management_subnet_id` - Management subnet ID
- `bastion_host_id` - Bastion host ID
- `route_table_id` - Route table ID

---

### networking/spoke-vnet

Creates spoke VNets with customizable subnets.

**Inputs:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| resource_group_name | string | yes | Resource group name |
| location | string | yes | Azure region |
| location_short | string | yes | Short region name |
| environment | string | yes | Environment |
| spoke_name | string | yes | Spoke identifier (e.g., aks, app) |
| address_space | string | yes | VNet CIDR |
| subnets | map(object) | yes | Subnet configurations |
| create_route_table | bool | no | Create UDR (default: true) |
| firewall_private_ip | string | no | Firewall IP for routing |

**Outputs:**
- `vnet_id` - Spoke VNet resource ID
- `vnet_name` - Spoke VNet name
- `subnet_ids` - Map of subnet names to IDs
- `route_table_id` - Route table ID

---

### networking/vnet-peering

Creates bi-directional VNet peering between hub and spoke.

**Inputs:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| hub_vnet_id | string | yes | Hub VNet resource ID |
| hub_vnet_name | string | yes | Hub VNet name |
| hub_resource_group_name | string | yes | Hub resource group |
| spoke_vnet_id | string | yes | Spoke VNet resource ID |
| spoke_vnet_name | string | yes | Spoke VNet name |
| spoke_resource_group_name | string | yes | Spoke resource group |
| spoke_name | string | yes | Spoke identifier |
| allow_gateway_transit | bool | no | Allow gateway transit (default: true) |
| use_remote_gateways | bool | no | Use remote gateways (default: false) |

**Outputs:**
- `hub_to_spoke_peering_id` - Hub to spoke peering ID
- `spoke_to_hub_peering_id` - Spoke to hub peering ID

---

### networking/azure-firewall

Creates Azure Firewall with policy and rule collections.

**Inputs:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| resource_group_name | string | yes | Resource group name |
| location | string | yes | Azure region |
| location_short | string | yes | Short region name |
| environment | string | yes | Environment |
| firewall_subnet_id | string | yes | AzureFirewallSubnet ID |
| firewall_sku | string | no | Standard or Premium (default: Standard) |
| availability_zones | list(string) | no | Zones (default: [1,2,3]) |
| network_rule_collections | map(object) | no | Network rules |
| application_rule_collections | map(object) | no | Application rules |

**Outputs:**
- `firewall_id` - Firewall resource ID
- `firewall_name` - Firewall name
- `firewall_private_ip` - Private IP address
- `firewall_public_ip` - Public IP address
- `firewall_policy_id` - Policy ID

---

### networking/nsg

Creates Network Security Groups with rules.

**Inputs:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| resource_group_name | string | yes | Resource group name |
| location | string | yes | Azure region |
| location_short | string | yes | Short region name |
| environment | string | yes | Environment |
| nsg_name | string | yes | NSG identifier |
| security_rules | map(object) | no | Security rule definitions |
| subnet_ids | map(string) | no | Subnets to associate |
| enable_flow_logs | bool | no | Enable NSG flow logs |

**Outputs:**
- `nsg_id` - NSG resource ID
- `nsg_name` - NSG name
- `security_rule_ids` - Map of rule names to IDs

---

### compute/aks

Creates Azure Kubernetes Service cluster with node pools.

**Inputs:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| resource_group_name | string | yes | Resource group name |
| location | string | yes | Azure region |
| location_short | string | yes | Short region name |
| environment | string | yes | Environment |
| cluster_name | string | yes | Cluster name |
| subnet_id | string | yes | Subnet for AKS nodes |
| kubernetes_version | string | no | K8s version |
| system_node_pool | object | yes | System pool config |
| node_pools | map(object) | no | Additional node pools |
| network_plugin | string | no | azure or kubenet |
| enable_azure_ad_integration | bool | no | Enable AAD (default: true) |
| enable_workload_identity | bool | no | Enable WI (default: true) |
| private_cluster_enabled | bool | no | Private cluster |
| log_analytics_workspace_id | string | no | LAW for monitoring |

**Outputs:**
- `cluster_id` - AKS cluster ID
- `cluster_name` - Cluster name
- `cluster_fqdn` - Public FQDN
- `cluster_private_fqdn` - Private FQDN
- `kube_config` - Kubeconfig (sensitive)
- `oidc_issuer_url` - OIDC issuer for workload identity
- `node_resource_group` - Node resource group name
- `kubelet_identity` - Kubelet managed identity
- `identity` - Cluster managed identity

---

### compute/vm

Creates Linux or Windows virtual machines.

**Inputs:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| resource_group_name | string | yes | Resource group name |
| location | string | yes | Azure region |
| location_short | string | yes | Short region name |
| environment | string | yes | Environment |
| subnet_id | string | yes | Subnet for VMs |
| vms | map(object) | yes | VM configurations |

**VM Object:**
```hcl
vms = {
  myvm = {
    size           = "Standard_D4s_v5"
    os_type        = "Linux"  # or "Windows"
    admin_username = "azureuser"
    ssh_public_key = "ssh-rsa ..."  # Linux only
    admin_password = "..."          # Windows only
    zone           = "1"
    image = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = "latest"
    }
  }
}
```

**Outputs:**
- `linux_vm_ids` - Map of Linux VM IDs
- `windows_vm_ids` - Map of Windows VM IDs
- `linux_vm_private_ips` - Map of Linux private IPs
- `windows_vm_private_ips` - Map of Windows private IPs

---

### security/key-vault

Creates Azure Key Vault with RBAC.

**Inputs:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| resource_group_name | string | yes | Resource group name |
| location | string | yes | Azure region |
| location_short | string | yes | Short region name |
| environment | string | yes | Environment |
| vault_name | string | yes | Vault name suffix |
| sku_name | string | no | standard or premium |
| purge_protection_enabled | bool | no | Enable purge protection |
| administrator_object_ids | list(string) | no | Admin principal IDs |
| secrets_user_object_ids | list(string) | no | Secrets reader IDs |
| private_endpoint_subnet_id | string | no | Subnet for PE |

**Outputs:**
- `vault_id` - Key Vault ID
- `vault_name` - Key Vault name
- `vault_uri` - Key Vault URI
- `private_endpoint_ip` - Private endpoint IP

---

### security/managed-identity

Creates User-Assigned Managed Identity with role assignments.

**Inputs:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| resource_group_name | string | yes | Resource group name |
| location | string | yes | Azure region |
| location_short | string | yes | Short region name |
| environment | string | yes | Environment |
| identity_name | string | yes | Identity name suffix |
| role_assignments | map(object) | no | RBAC assignments |
| federated_identity_credentials | map(object) | no | For workload identity |

**Outputs:**
- `identity_id` - Identity resource ID
- `principal_id` - Service principal ID
- `client_id` - Application/client ID
- `tenant_id` - Azure AD tenant ID

---

### monitoring/log-analytics

Creates Log Analytics workspace with solutions.

**Inputs:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| resource_group_name | string | yes | Resource group name |
| location | string | yes | Azure region |
| location_short | string | yes | Short region name |
| environment | string | yes | Environment |
| workspace_name | string | yes | Workspace name suffix |
| retention_in_days | number | no | Data retention (default: 30) |
| solutions | list(string) | no | Solutions to deploy |
| alert_rules | map(object) | no | Scheduled query alerts |

**Outputs:**
- `workspace_id` - Workspace resource ID
- `workspace_name` - Workspace name
- `workspace_customer_id` - Workspace GUID
- `primary_shared_key` - Primary key (sensitive)

---

### storage/storage-account

Creates Azure Storage Account with containers.

**Inputs:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| resource_group_name | string | yes | Resource group name |
| location | string | yes | Azure region |
| location_short | string | yes | Short region name |
| environment | string | yes | Environment |
| storage_name | string | yes | Name (alphanumeric only) |
| account_replication_type | string | no | LRS, GRS, ZRS, etc. |
| containers | map(object) | no | Blob containers |
| file_shares | map(object) | no | File shares |
| lifecycle_rules | map(object) | no | Lifecycle policies |
| private_endpoint_subnet_id | string | no | Subnet for PE |

**Outputs:**
- `storage_account_id` - Storage account ID
- `storage_account_name` - Account name
- `primary_blob_endpoint` - Blob endpoint URL
- `primary_access_key` - Access key (sensitive)
- `container_ids` - Map of container names to IDs

---

## Environment Differences

| Feature | Dev | Staging | Prod |
|---------|-----|---------|------|
| Availability Zones | No | Yes | Yes |
| Azure Firewall | Optional | Yes | Yes (Premium) |
| Firewall SKU | Standard | Standard | Premium |
| AKS Node Count | 1-3 | 2-8 | 3-20 |
| AKS VM Size | D2s | D4s | D8s |
| Storage Redundancy | LRS | ZRS | GZRS |
| Key Vault SKU | Standard | Standard | Premium |
| Purge Protection | No | Yes | Yes |
| Private Endpoints | No | Optional | Yes |
| Log Retention | 30 days | 60 days | 90 days |
| Resource Deletion | Allowed | Protected | Protected |

---

## Naming Conventions

Following Azure CAF:

```
<resource-type>-<workload>-<environment>-<region>-<instance>
```

| Resource | Pattern | Example |
|----------|---------|---------|
| Resource Group | rg-{purpose}-{env}-{region}-001 | rg-network-hub-prod-eus-001 |
| Virtual Network | vnet-{purpose}-{env}-{region}-001 | vnet-hub-prod-eus-001 |
| Subnet | snet-{purpose}-{env}-{region}-001 | snet-aks-nodes-prod-eus-001 |
| NSG | nsg-{purpose}-{env}-{region}-001 | nsg-aks-prod-eus-001 |
| Azure Firewall | afw-{env}-{region}-001 | afw-prod-eus-001 |
| AKS Cluster | aks-{name}-{env}-{region}-001 | aks-platform-prod-eus-001 |
| Key Vault | kv-{name}-{env}-{region}-001 | kv-secrets-prod-eus-001 |
| Storage Account | st{name}{env}{region}001 | stplatformprodeus001 |
| Log Analytics | log-{name}-{env}-{region}-001 | log-platform-prod-eus-001 |
| Managed Identity | id-{name}-{env}-{region}-001 | id-aks-prod-eus-001 |

---

## Security Best Practices

1. **Network Security**
   - All traffic through Azure Firewall in production
   - NSG deny-all default rules
   - Private endpoints for PaaS services
   - No public IPs on internal resources

2. **Identity**
   - Managed Identities only (no service principal secrets)
   - Key Vault RBAC (not access policies)
   - Azure AD integration for AKS
   - Workload Identity for pod authentication

3. **Data Protection**
   - Infrastructure encryption enabled
   - Customer-managed keys for sensitive workloads
   - Soft delete and purge protection
   - Geo-redundant storage for production

4. **Compliance**
   - Azure Policy enforcement
   - Diagnostic logs to Log Analytics
   - NSG flow logs enabled
   - Microsoft Defender for Cloud
