# =============================================================================
# Staging Environment - Backend Configuration
# =============================================================================

resource_group_name  = "rg-tfstate-staging-eus-001"
storage_account_name = "sttfstatestagingeus001"
container_name       = "tfstate"
key                  = "staging.terraform.tfstate"
