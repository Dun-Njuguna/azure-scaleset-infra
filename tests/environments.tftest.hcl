# Plans the whole stack against MOCKED providers: no Azure account needed.
# Run once per environment so every tfvars file is checked:
#   make test   (or: terraform test -var-file=envs/common.tfvars -var-file=envs/<env>.tfvars)

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000000"
      object_id = "11111111-1111-1111-1111-111111111111"
    }
  }

  # Realistic ARM IDs: the provider validates ID formats even when mocked.
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock"
    }
  }
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock"
    }
  }
  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock/subnets/snet-mock"
    }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/networkSecurityGroups/nsg-mock"
    }
  }
  mock_resource "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/privateDnsZones/mock.example.com"
    }
  }
  mock_resource "azurerm_public_ip" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/publicIPAddresses/pip-mock"
    }
  }
  mock_resource "azurerm_lb" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/loadBalancers/lb-mock"
    }
  }
  mock_resource "azurerm_lb_backend_address_pool" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/loadBalancers/lb-mock/backendAddressPools/app"
    }
  }
  mock_resource "azurerm_lb_probe" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/loadBalancers/lb-mock/probes/http-ready"
    }
  }
  mock_resource "azurerm_key_vault" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.KeyVault/vaults/kv-mock"
    }
  }
  mock_resource "azurerm_postgresql_flexible_server" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.DBforPostgreSQL/flexibleServers/psql-mock"
    }
  }
  mock_resource "azurerm_managed_redis" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Cache/redisEnterprise/redis-mock"
    }
  }
  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.OperationalInsights/workspaces/log-mock"
    }
  }
  mock_resource "azurerm_monitor_action_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Insights/actionGroups/ag-mock"
    }
  }

  mock_resource "azurerm_linux_virtual_machine_scale_set" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Compute/virtualMachineScaleSets/vmss-mock"
    }
  }
}
mock_provider "random" {}
mock_provider "tls" {
  mock_resource "tls_private_key" {
    defaults = {
      public_key_openssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICYMDInuga1xdI1OzHooqAQB0M2/HeGjgafMxga5Vsar mock"
    }
  }
}
mock_provider "time" {}

run "environment_settings_are_applied" {
  command = plan

  assert {
    condition     = module.governance.lock_enabled == (var.environment == "prod")
    error_message = "Only prod should have a delete lock."
  }

  assert {
    condition     = length(module.redis) == (var.redis.enabled ? 1 : 0)
    error_message = "Redis must exist exactly when redis.enabled is true."
  }

  assert {
    condition     = (output.ssh == null) == !var.ssh_enabled
    error_message = "SSH details must only be exposed when ssh_enabled is true."
  }

  assert {
    condition     = var.environment != "prod" || (var.postgres.high_availability_enabled && var.postgres.geo_redundant_backup_enabled)
    error_message = "Prod Postgres must be highly available with geo-redundant backups."
  }

  assert {
    condition     = var.environment != "prod" || !var.autoscale_schedule_enabled
    error_message = "Prod must never scale to zero on a schedule."
  }

  assert {
    condition     = var.environment != "prod" || var.key_vault_purge_protection
    error_message = "Prod Key Vault needs purge protection."
  }
}

run "users_follow_their_environment_list" {
  command = plan

  assert {
    condition = alltrue([
      for name, u in var.users : contains(keys(output.users), name) == contains(u.environments, var.environment)
    ])
    error_message = "A user must exist in an environment if and only if they list it."
  }
}

run "resource_names_include_the_environment" {
  command = plan

  assert {
    condition     = output.resource_group_name == "rg-${var.project}-${var.environment}"
    error_message = "Resource group must be named per environment, so environments can't collide."
  }
}
