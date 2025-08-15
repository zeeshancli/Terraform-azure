org_prefix   = "acme"
environment  = "dev"
location     = "eastus"

address_space = ["10.10.0.0/16"]

subnet_prefixes = {
  appgw             = ["10.10.0.0/24"]
  private_endpoints = ["10.10.1.0/24"]
  app               = ["10.10.2.0/24"]
  data              = ["10.10.3.0/24"]
}

webapp_network_mode = "private_endpoint"
sql_network_mode    = "private_endpoint"

webapp_settings = {
  ASPNETCORE_ENVIRONMENT = "Development"
  WEBSITES_PORT          = "8080"
}

webapp_sku = "P1v3"

webapp_stack = {
  kind     = "linux"
  linux_fx = "DOTNET|8.0"
}

sql_admin_login    = "sqladminuser"
sql_admin_password = "Dev-ChangeMe-123!"