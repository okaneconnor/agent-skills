#!/bin/bash
# =============================================================================
# Bootstrap Terraform Backend Storage
# Creates Azure Storage Account for Terraform state files
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
LOCATION="eastus"
ENVIRONMENT="dev"
SUBSCRIPTION_ID=""

# Usage function
usage() {
    echo "Usage: $0 --subscription <subscription-id> [--location <location>] [--environment <env>]"
    echo ""
    echo "Options:"
    echo "  --subscription, -s   Azure subscription ID (required)"
    echo "  --location, -l       Azure region (default: eastus)"
    echo "  --environment, -e    Environment name (default: dev)"
    echo "  --help, -h           Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --subscription 12345678-1234-1234-1234-123456789012 --environment prod"
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --subscription|-s)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        --location|-l)
            LOCATION="$2"
            shift 2
            ;;
        --environment|-e)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$SUBSCRIPTION_ID" ]]; then
    echo -e "${RED}Error: Subscription ID is required${NC}"
    usage
fi

# Generate names
LOCATION_SHORT=$(echo "$LOCATION" | sed 's/east/e/;s/west/w/;s/north/n/;s/south/s/;s/central/c/;s/us/us/;s/europe/eu/')
RESOURCE_GROUP="rg-tfstate-${ENVIRONMENT}-${LOCATION_SHORT}-001"
STORAGE_ACCOUNT="sttfstate${ENVIRONMENT}${LOCATION_SHORT}001"
CONTAINER_NAME="tfstate"

echo -e "${GREEN}=== Terraform Backend Bootstrap ===${NC}"
echo ""
echo "Configuration:"
echo "  Subscription:     $SUBSCRIPTION_ID"
echo "  Location:         $LOCATION"
echo "  Environment:      $ENVIRONMENT"
echo "  Resource Group:   $RESOURCE_GROUP"
echo "  Storage Account:  $STORAGE_ACCOUNT"
echo "  Container:        $CONTAINER_NAME"
echo ""

# Confirm
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo -e "${YELLOW}Setting subscription...${NC}"
az account set --subscription "$SUBSCRIPTION_ID"

echo -e "${YELLOW}Creating resource group...${NC}"
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --tags Environment="$ENVIRONMENT" Purpose="TerraformState" ManagedBy="Bootstrap" \
    --output none

echo -e "${YELLOW}Creating storage account...${NC}"
az storage account create \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard_GRS \
    --kind StorageV2 \
    --access-tier Hot \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --https-only true \
    --tags Environment="$ENVIRONMENT" Purpose="TerraformState" ManagedBy="Bootstrap" \
    --output none

echo -e "${YELLOW}Enabling versioning and soft delete...${NC}"
az storage account blob-service-properties update \
    --account-name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --enable-versioning true \
    --enable-delete-retention true \
    --delete-retention-days 30 \
    --enable-container-delete-retention true \
    --container-delete-retention-days 30 \
    --output none

echo -e "${YELLOW}Creating blob container...${NC}"
az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT" \
    --auth-mode login \
    --output none

echo -e "${YELLOW}Enabling storage account firewall (optional)...${NC}"
# Uncomment to restrict access to specific IPs/VNets
# az storage account network-rule add \
#     --account-name "$STORAGE_ACCOUNT" \
#     --resource-group "$RESOURCE_GROUP" \
#     --ip-address "YOUR_IP_ADDRESS" \
#     --output none

echo ""
echo -e "${GREEN}=== Bootstrap Complete ===${NC}"
echo ""
echo "Backend configuration for environments/${ENVIRONMENT}/backend.tfvars:"
echo ""
echo "resource_group_name  = \"$RESOURCE_GROUP\""
echo "storage_account_name = \"$STORAGE_ACCOUNT\""
echo "container_name       = \"$CONTAINER_NAME\""
echo "key                  = \"${ENVIRONMENT}.terraform.tfstate\""
echo ""
echo "Initialize Terraform with:"
echo "  cd environments/${ENVIRONMENT}"
echo "  terraform init -backend-config=backend.tfvars"
