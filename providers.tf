provider "azurerm" {
  # Subscription comes from ARM_SUBSCRIPTION_ID or the Azure CLI login.
  features {
    resource_group {
      # Refuse to delete a resource group that still has resources Terraform
      # doesn't know about.
      prevent_deletion_if_contains_resources = true
    }

    key_vault {
      # Keep soft-deleted secrets recoverable instead of purging on destroy.
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }

    virtual_machine_scale_set {
      # Changes that need instances updated trigger a rolling upgrade.
      roll_instances_when_required = true
    }
  }
}
