---
name: azure-terraform-infrastructure
description: Generate Azure Landing Zone infrastructure with Terraform following Microsoft Cloud Adoption Framework. Use when asked to create Azure infrastructure, Terraform modules, Azure DevOps pipelines, or cloud architecture for Azure. Includes hub-spoke networking, AKS, VMs, Key Vault, and monitoring.
---

# Azure Terraform Infrastructure Skill

Generate production-ready Azure infrastructure using Terraform, following Microsoft's Cloud Adoption Framework (CAF) and Azure Landing Zone patterns.

## When to Use

- Asked to create Azure infrastructure, an Azure landing zone, or hub-spoke networking with Terraform
- Scaffolding Terraform modules for AKS, VMs, Key Vault, Azure Firewall, NSGs, Log Analytics, managed identities, or storage accounts
- Setting up Azure DevOps pipelines for Terraform (PR validation, plan → approve → apply per environment)

Skip it for other clouds, for Bicep / ARM templates, or for modules that must be Azure Verified Modules (AVM) certified.

## Quick Start

When asked to create Azure infrastructure, use the templates in `templates/` as a starting point. `<skill-dir>` below is this skill's base directory — the folder this `SKILL.md` was loaded from.

```bash
# Copy templates (including dotfiles such as .azure-pipelines/) to the target project
cp -R <skill-dir>/templates/. ./azure-infrastructure/
mv ./azure-infrastructure/gitignore.template ./azure-infrastructure/.gitignore
```

The template's ignore file ships as `gitignore.template` so it doesn't apply inside this skills repo; rename it to `.gitignore` in the generated project.

## What This Skill Provides

### Architecture Pattern: Hub-Spoke Networking
- **Hub VNet**: Centralized services (Firewall, Bastion, VPN Gateway)
- **Spoke VNets**: Workload-specific networks (AKS, VMs, Data)
- **VNet Peering**: Bi-directional connectivity between hub and spokes

### Modules Included
| Module | Purpose |
|--------|---------|
| `hub-vnet` | Central hub network with Firewall, Bastion subnets |
| `spoke-vnet` | Workload networks with customizable subnets |
| `vnet-peering` | Bi-directional VNet peering |
| `azure-firewall` | Centralized egress with policy rules |
| `nsg` | Network security groups with flow logs |
| `aks` | Azure Kubernetes Service with node pools |
| `vm` | Virtual machines with managed disks |
| `key-vault` | Secrets management with RBAC |
| `managed-identity` | User-assigned managed identities |
| `log-analytics` | Central logging workspace |
| `storage-account` | Storage with security best practices |

### CI/CD Pipelines (Azure DevOps)
- **PR Validation**: Format check, validate, security scan, plan
- **Deploy Pipeline**: Plan → Approve → Apply for each environment

### Environments
- Development (dev)
- Staging (staging)
- Production (prod)

## Usage Instructions

### 1. Initialize a New Project

```bash
# Create project directory
mkdir -p my-azure-infra
cd my-azure-infra

# Copy all templates (including dotfiles)
cp -R <skill-dir>/templates/. .
mv gitignore.template .gitignore

# Initialize Terraform
cd environments/dev
terraform init -backend-config=backend.tfvars
```

### 2. Customize Variables

Edit `environments/<env>/terraform.tfvars`:

```hcl
# Core settings
project_name    = "myproject"
environment     = "dev"
location        = "eastus"

# Network CIDRs
hub_vnet_cidr   = "10.0.0.0/16"
aks_spoke_cidr  = "10.1.0.0/16"
vm_spoke_cidr   = "10.2.0.0/16"
```

### 3. Bootstrap State Storage

```bash
# Create Azure resources for Terraform state
./scripts/bootstrap-backend.sh \
  --subscription "your-subscription-id" \
  --location "eastus" \
  --environment "dev"
```

### 4. Deploy

```bash
cd environments/dev
terraform plan -out=tfplan
terraform apply tfplan
```

## Naming Convention

Following Azure CAF naming:
```
<resource-type>-<workload>-<environment>-<region>-<instance>

Examples:
- rg-network-hub-prod-eastus-001
- vnet-hub-prod-eastus-001
- aks-platform-dev-eastus-001
```

## Network Topology

```
                    HUB VNET (10.0.0.0/16)
                    ├── AzureFirewallSubnet (10.0.1.0/24)
                    ├── GatewaySubnet (10.0.2.0/24)
                    ├── AzureBastionSubnet (10.0.3.0/27)
                    └── ManagementSubnet (10.0.4.0/24)
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
    AKS Spoke           VM Spoke            Data Spoke
    10.1.0.0/16         10.2.0.0/16         10.3.0.0/16
```

## Security Best Practices Included

- No public IPs on internal resources
- Private endpoints for PaaS services
- NSG deny-all default with explicit allow rules
- Azure Firewall for egress filtering
- Managed Identities (no service principal secrets)
- Key Vault with RBAC access model
- Diagnostic logs to Log Analytics

## Pipeline Setup (Azure DevOps)

### Required Service Connections
Create ARM service connections for each environment:
- `azure-dev-connection`
- `azure-staging-connection`
- `azure-prod-connection`

### Required Variable Groups
Create variable groups in Azure DevOps:
- `terraform-common`: Shared settings
- `terraform-dev`: Dev-specific secrets
- `terraform-staging`: Staging-specific secrets
- `terraform-prod`: Prod-specific secrets

## File Reference

See [REFERENCE.md](REFERENCE.md) for detailed documentation on each module's inputs and outputs.
