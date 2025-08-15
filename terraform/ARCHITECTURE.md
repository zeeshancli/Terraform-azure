# Architecture and Module Interactions

This document explains how modules interact, how naming and parameters are applied, and how dependencies are enforced.

## Modules and data flow

Root
- Creates/uses a Resource Group
- Instantiates modules in the following conceptual order:
  1) network (produces vnet_id and subnet_ids)
  2) dns (creates private zones and links to the VNet)
  3) web_app (creates App Service in the chosen network mode)
  4) sql (creates SQL in the chosen network mode)
  5) app_gateway (consumes Web App default hostname and AppGW subnet)

Produced values:
- module.network.subnet_ids are passed into web_app, sql, and app_gateway
- module.dns.webapp_zone_id and module.dns.sql_zone_id are passed into web_app and sql when using Private Endpoints
- module.web_app.default_hostname is passed into app_gateway.backend_fqdn

## Naming conventions

All modules receive a name_prefix built from:
org_prefix + environment + location_short

Example: acme-dev-eus

Each module uses this prefix for its resources:
- network: -vnet, -snet-*, -nsg-*
- dns: private DNS zones and VNet links
- web_app: -asp (plan), -web (app)
- sql_database: -sql-xxxxx (server), -sqldb (database)
- app_gateway: -agw, -agw-pip

## Parameters and environment changes

You can switch environments by selecting a different tfvars. The same root code deploys differently configured stacks based on:
- address_space and subnet_prefixes
- network modes (private_endpoint vs service_endpoint)
- SKUs (App Service, SQL)
- app settings and runtime stack

No per-environment code branching is required.

## Dependency handling

- Implicit dependencies are created by passing IDs/attributes:
  - AppGW depends on the AppGW subnet, backend FQDN, and VNet-linked DNS resolving private addresses when PE mode is used
  - Web App and SQL Private Endpoints depend on their subnet and the existence of the target resource
- Explicit dependencies (depends_on) are used in root to guarantee DNS zones and VNet links exist before creating Private Endpoints or before AppGW resolves the backend hostname:
  - module.web_app and module.sql depend_on module.dns
  - module.app_gateway depends_on module.dns and module.web_app

## Network security (NSGs and policies)

- NSGs are applied to app and data subnets with sample allow rules for typical flows (AppGW->443, App->1433)
- AppGW subnet is left without NSG to avoid blocking required platform traffic
- Private Endpoint subnet disables private endpoint network policies as required by Azure
- Note: NSGs do not filter Private Endpoint NICs; access control is via Private Endpoint approvals and DNS

## Web App network modes

- private_endpoint:
  - Web App public network access disabled
  - Private Endpoint created in PE subnet
  - Private DNS zone group attaches to privatelink.azurewebsites.net
  - AppGW uses the Web App default hostname; DNS resolves to private IP inside VNet

- service_endpoint:
  - Web App remains public
  - AppGW and/or App subnet enables Microsoft.Web service endpoints
  - Web App Access Restrictions:
    - allow only the AppGW subnet
    - deny all as a default
  - This lets you restrict inbound to your VNet without changing core code

## SQL network modes

- private_endpoint:
  - Public network disabled on server
  - Private Endpoint in PE subnet
  - Private DNS zone group attaches to privatelink.database.windows.net

- service_endpoint:
  - Public network enabled
  - VNet rules created on SQL server for allowed subnets (AppGW, App)
  - No IP firewall rules required; VNet rules govern access

## Application Gateway

- WAF_v2 configured in Prevention mode
- Public IP frontend on port 80 for simplicity
- Backend to Web App via HTTPS (port 443), host header picked from backend FQDN
- Health probe on "/"

To add TLS on the frontend, introduce:
- SSL certificate (Key Vault or local)
- HTTPS listener and associated HTTP settings

## DNS

- When Private Endpoints are used, private zones are created and linked:
  - Web App: privatelink.azurewebsites.net
  - SQL: privatelink.database.windows.net
- Private DNS Zone Groups on Private Endpoint resources ensure A records are registered
