# AzureRM backend configuration for dev
resource_group_name  = "tfstate-rg"
storage_account_name = "tfstateacme123"   # must be globally unique
container_name       = "tfstate"
key                  = "acme-dev-eus.tfstate"

# Use Azure AD auth (recommended)
use_azuread_auth = true
subscription_id  = "<your-subscription-id>"
tenant_id        = "<your-tenant-id>"