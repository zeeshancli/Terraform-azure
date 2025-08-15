provider "azurerm" {
  features {}

  # Optional: set default tags across all resources
  default_tags = {
    environment = var.environment
    org         = var.org_prefix
  }
}