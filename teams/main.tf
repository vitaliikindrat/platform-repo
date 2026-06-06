terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name = "rg-oidc-demo"
    container_name      = "tfstate"
    key                 = "platform-teams.tfstate"
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

provider "azuread" {}

data "azurerm_subscription" "current" {}
data "azuread_client_config" "current" {}

# Shared ACR and storage — platform-owned, referenced here to assign team roles
data "azurerm_container_registry" "shared" {
  name                = "acroidcbfea0dc0"
  resource_group_name = "rg-oidc-demo"
}

data "azurerm_storage_account" "tfstate" {
  name                = "sttfstatebfea0dc0"
  resource_group_name = "rg-oidc-demo"
}
