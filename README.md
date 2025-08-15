# Azure Terraform Modular Repository

This repository provisions a simple, modular Azure application stack designed for reusability across environments (dev, test, prod). The solution is intentionally scoped so a single engineer can build, understand, and deploy it within two days.

What it deploys:
- Network module: VNet, subnets, and NSGs
- DNS module: Private DNS zones for Web App and SQL when using Private Endpoints
- Web App module: Linux App Service with two network models
  - private_endpoint: Web App is private, reachable only over Private Link
  - service_endpoint: Web App is public but restricted to an Azure subnet (App Gateway subnet) via Access Restrictions and Service Endpoints
- SQL Database module: Azure SQL Server + Database with two network models
  - private_endpoint: SQL is private via Private Link
  - service_endpoint: SQL uses service endpoints and VNet rules
- Application Gateway module: Public entry point with WAF_v2, routing to the Web App, and backend health probe

Key design goals:
- Modular design: one module per resource type, reusable and composable
- Parameter-driven: environment-specific settings passed via tfvars; no code duplication
- Consistent naming: org-env-location prefix using locals, applied consistently across modules
- Clear dependencies: both implicit (resource references) and explicit (depends_on) to guarantee correct creation order

## Structure

- modules/network: VNet, subnets, basic NSGs
  - Implicit dependency: downstream modules consume subnet IDs
  - Notes: NSGs do not apply to Private Endpoint NICs; subnet policies are disabled for PE subnet
- modules/dns: Private DNS zones for Web App and SQL private endpoints and VNet links
  - Explicit dependency: web and sql modules depend_on DNS so Private DNS is linked before PE resolution
- modules/web_app: App Service Plan + Linux Web App
  - private_endpoint mode: public_network_access disabled; Private Endpoint + DNS zone group
  - service_endpoint mode: configure Access Restrictions allowing only the AppGW subnet (using subnet-based rule); defaults to deny all
- modules/sql_database: SQL Server + Database
  - private_endpoint mode: public network disabled; Private Endpoint + DNS zone group
  - service_endpoint mode: enable VNet rules for allowed subnets; public network stays enabled, but access is restricted by those rules
- modules/app_gateway: Public IP + WAF_v2 App Gateway
  - Backend FQDN is the Web App default hostname
  - If Web App is in private_endpoint mode, DNS resolution (via Private DNS zone linked to VNet) makes AppGW reach the private IP transparently

## How naming works

A consistent prefix is generated as:
org-prefix + environment + location-short
For example: acme-dev-eus

Modules create resources with that prefix and a short suffix, e.g.:
- acme-dev-eus-vnet
- acme-dev-eus-snet-appgw
- acme-dev-eus-agw, acme-dev-eus-agw-pip
- acme-dev-eus-web, acme-dev-eus-sql-xxxxx

## Parameters and environment-specific configuration

Set modes per environment:
- webapp_network_mode: private_endpoint or service_endpoint
- sql_network_mode: private_endpoint or service_endpoint

Use tfvars to change SKUs, address spaces, stacks, and settings without code changes. Examples provided in envs/dev.tfvars and envs/prod.tfvars.

## Dependencies and ordering

- Implicit: subnet IDs flow into Web App, SQL, and App Gateway; Web App hostname flows into App Gateway; DNS zone IDs flow into Private Endpoint zone groups
- Explicit: depends_on in root for app_gateway, web_app, and sql to ensure DNS zones and VNet links exist before Private Endpoints are established and before AppGW tries to resolve private FQDNs

## NSG considerations

- NSGs are provided on app and data subnets with sample rules (allow 443 from AppGW to app subnet, allow 1433 from app to data)
- NSGs do not apply to Private Endpoint NICs
- App Gateway subnet is left without an NSG to avoid inadvertently blocking required control/data plane traffic (recommended practice)

## Prerequisites

- Terraform >= 1.6
- AzureRM provider ~> 3.100
- Azure subscription and rights to deploy App Service, SQL, Application Gateway, etc.

Login:
```
az login
az account set --subscription "<your-subscription-id>"
```

## Getting started

1) Copy envs/dev.tfvars or envs/prod.tfvars and adjust as needed
2) Initialize:
```
terraform init
```
3) Plan:
```
terraform plan -var-file="envs/dev.tfvars"
```
4) Apply:
```
terraform apply -var-file="envs/dev.tfvars"
```

Outputs:
- app_gateway_public_ip and app_gateway_frontend_url
- web_app_default_hostname
- sql_server_fqdn

## Switching models (without code changes)

- Web App: toggle between private_endpoint and service_endpoint by changing webapp_network_mode in tfvars
  - private_endpoint: Web App private; AppGW resolves *.azurewebsites.net to private IP via Private DNS
  - service_endpoint: Web App remains public, but Access Restrictions permit only requests from the AppGW subnet (leveraging Microsoft.Web service endpoints)
- SQL: toggle sql_network_mode similarly
  - private_endpoint: Server is private, private DNS resolves to PE IP
  - service_endpoint: Public network is enabled; VNet rules restrict access to configured subnets

## SSL/TLS note

This sample configures App Gateway with an HTTP listener to keep the solution simple. In production, you should:
- add an HTTPS listener and certificate
- optionally use end-to-end TLS to the Web App and configure health probes appropriately

## Resource-to-resource communication and DNS

- AppGW -> Web App:
  - Private endpoint mode: DNS zone privatelink.azurewebsites.net linked to VNet ensures the default hostname resolves to a private IP
  - Service endpoint mode: requests go over public endpoint, but Web App access restrictions allow only traffic associated with the AppGW subnet
- App/Web -> SQL:
  - Private endpoint mode: privatelink.database.windows.net resolves to private IP
  - Service endpoint mode: SQL allows traffic only from configured VNet subnets via VNet rules

## Clean up

```
terraform destroy -var-file="envs/dev.tfvars"
```