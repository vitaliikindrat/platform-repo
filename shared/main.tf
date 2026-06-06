terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name = "rg-oidc-demo"
    container_name      = "tfstate"
    key                 = "platform-shared.tfstate"
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

# Platform-owned resource group. Teams have no role here.
# They reference resources in this RG via data sources (read-only lookup).
data "azurerm_resource_group" "platform" {
  name = "rg-platform-shared"
}

# One Log Analytics workspace for the whole platform.
# Container App Environment requires one. Teams' apps emit logs here.
# Platform controls retention, alerts, and access to the workspace.
# Failure mode: if you give teams Contributor on this RG they can delete it
# and take down every Container App environment in the platform.
resource "azurerm_log_analytics_workspace" "platform" {
  name                = "law-platform-shared"
  resource_group_name = data.azurerm_resource_group.platform.name
  location            = data.azurerm_resource_group.platform.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# One shared Container App Environment. All teams deploy Container Apps here.
# Lives in rg-platform-shared — teams cannot touch it.
# Consumption plan: no base cost, pay per use. Right choice for a learning platform.
# Dedicated plan: fixed cost, more isolation. Right choice for prod with SLA requirements.
resource "azurerm_container_app_environment" "platform" {
  name                       = "cae-platform-shared"
  resource_group_name        = data.azurerm_resource_group.platform.name
  location                   = data.azurerm_resource_group.platform.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform.id
}
