# Azure Landing Zone Infrastructure

Production-ready Azure infrastructure using Terraform, following Microsoft's Cloud Adoption Framework (CAF).

## Architecture

```
                    HUB VNET (10.0.0.0/16)
                    ├── Azure Firewall
                    ├── VPN Gateway
                    ├── Bastion Host
                    └── Management Subnet
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
    AKS Spoke           VM Spoke            Data Spoke
    (10.1.0.0/16)       (10.2.0.0/16)       (10.3.0.0/16)
```

## Prerequisites

- Terraform >= 1.6.0
- Azure CLI >= 2.50.0
- Azure subscription with Owner/Contributor access
- Azure DevOps organization (for CI/CD)

## Quick Start

### 1. Bootstrap State Storage

```bash
./scripts/bootstrap-backend.sh \
  --subscription "your-subscription-id" \
  --location "eastus" \
  --environment "dev"
```

### 2. Initialize Terraform

```bash
cd environments/dev
terraform init -backend-config=backend.tfvars
```

### 3. Review and Apply

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

## Directory Structure

```
.
├── .azure-pipelines/        # CI/CD pipeline definitions
│   ├── templates/           # Reusable pipeline templates
│   ├── pr-validation.yml    # PR validation pipeline
│   └── terraform-deploy.yml # Deployment pipeline
├── modules/                 # Reusable Terraform modules
│   ├── networking/          # Network resources
│   ├── compute/             # Compute resources (AKS, VMs)
│   ├── security/            # Security resources
│   ├── monitoring/          # Monitoring resources
│   └── storage/             # Storage resources
├── environments/            # Environment configurations
│   ├── dev/
│   ├── staging/
│   └── prod/
├── scripts/                 # Helper scripts
└── docs/                    # Documentation
```

## Modules

| Module | Description |
|--------|-------------|
| `hub-vnet` | Hub virtual network with Firewall and Bastion subnets |
| `spoke-vnet` | Spoke virtual network with customizable subnets |
| `vnet-peering` | Bi-directional VNet peering |
| `azure-firewall` | Azure Firewall with policy and rules |
| `nsg` | Network security groups |
| `aks` | Azure Kubernetes Service cluster |
| `vm` | Virtual machines |
| `key-vault` | Azure Key Vault |
| `managed-identity` | User-assigned managed identities |
| `log-analytics` | Log Analytics workspace |
| `storage-account` | Storage account |

## Environments

| Environment | Purpose | Subscription |
|-------------|---------|--------------|
| dev | Development and testing | Dev subscription |
| staging | Pre-production validation | Staging subscription |
| prod | Production workloads | Prod subscription |

## CI/CD

### Pipelines

1. **PR Validation** (`pr-validation.yml`)
   - Runs on pull requests
   - Terraform format check
   - Terraform validate
   - Security scanning (Checkov)
   - Terraform plan (all environments)

2. **Deploy** (`terraform-deploy.yml`)
   - Manual trigger
   - Plan → Approve → Apply for each environment
   - Sequential deployment: dev → staging → prod

### Setup

1. Create service connections in Azure DevOps:
   - `azure-dev-connection`
   - `azure-staging-connection`
   - `azure-prod-connection`

2. Create variable groups:
   - `terraform-common`
   - `terraform-dev`
   - `terraform-staging`
   - `terraform-prod`

## Naming Convention

Following Azure CAF naming standard:

```
<resource-type>-<workload>-<environment>-<region>-<instance>
```

Examples:
- `rg-network-hub-prod-eastus-001`
- `vnet-hub-prod-eastus-001`
- `aks-platform-dev-eastus-001`

## Security

- Private endpoints for PaaS services
- NSG deny-all default rules
- Azure Firewall egress filtering
- Managed identities (no secrets)
- Key Vault RBAC access model
- Diagnostic logs enabled

## Cost Optimization

- Right-sized resources per environment
- Auto-shutdown for dev VMs
- Reserved instances for production
- Cost alerts configured

## Contributing

1. Create a feature branch
2. Make changes
3. Run `terraform fmt -recursive`
4. Submit pull request
5. Wait for PR validation to pass

## License

MIT
