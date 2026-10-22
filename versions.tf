terraform {
  # 1.11+ for write-only attributes and ephemeral resources.
  required_version = ">= 1.11"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }

  # Partial config: filled in per environment from envs/<env>.backend.hcl.
  # Use scripts/tf.sh, which always pairs the backend with the matching tfvars.
  backend "azurerm" {}
}
