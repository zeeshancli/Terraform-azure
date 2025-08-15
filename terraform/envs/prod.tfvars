org_prefix   = "acme"
environment  = "prod"
location     = "eastus2"

address_space = ["10.20.0.0/16"]

subnet_prefixes = {
  appgw             = ["10.20.0.0/24"]
  private_endpoints = ["10.20.1.0/24"]
  app               = ["10.20.2.0/24"]
  data              = ["10.20.3.0/24"]
}

# Example: App uses service endpoint model (restricted to AppGW subnet), SQL stays private
webapp_network_mode = "service_endpoint"
sql_network_mode    = "private_endpoint"

webapp_settings = {
  ASPNETCORE_ENVIRONMENT = "Production"
  WEBSITES_PORT          = "8080"
}

webapp_sku = "P1v3"

webapp_stack = {
  kind     = "linux"
  linux_fx = "DOTNET|8.0"
}

sql_admin_login    = "sqladminuser"
sql_admin_password = "Prod-ChangeMe-Strong!"