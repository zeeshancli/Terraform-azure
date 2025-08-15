provider "azurerm" {
  features {}

  # Optional: set default tags across all resources
  default_tags {
    tags = {
      environment = var.environment
      org         = var.org_prefix
    }
  }
}