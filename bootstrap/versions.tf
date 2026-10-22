terraform {
  required_version = ">= 1.11"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Bootstrap keeps LOCAL state on purpose: it creates the storage that every
  # other state file lives in, so it can't store its own state there.
}

provider "azurerm" {
  features {}
  # Subscription comes from ARM_SUBSCRIPTION_ID or the Azure CLI login.
}
