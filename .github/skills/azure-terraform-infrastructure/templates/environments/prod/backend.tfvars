# =============================================================================
# Production Environment - Backend Configuration
# =============================================================================

resource_group_name  = "rg-tfstate-prod-eus-001"
storage_account_name = "sttfstateprodeus001"
container_name       = "tfstate"
key                  = "prod.terraform.tfstate"
