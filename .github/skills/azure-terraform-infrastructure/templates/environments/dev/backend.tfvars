# =============================================================================
# Dev Environment - Backend Configuration
# =============================================================================
# Run bootstrap-backend.sh first to create these resources

resource_group_name  = "rg-tfstate-dev-eus-001"
storage_account_name = "sttfstatedeveus001"
container_name       = "tfstate"
key                  = "dev.terraform.tfstate"
