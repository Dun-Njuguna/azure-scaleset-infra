resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                = "vmss-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.vm_size
  instances           = var.instances_default
  zones               = length(var.zones) > 0 ? var.zones : null
  overprovision       = false

  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_public_key
  }

  # Users, app image and config all live in custom_data. Changing any of them
  # changes the model, and the rolling upgrade below replaces every instance.
  custom_data = base64encode(local.cloud_init)

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }

  identity {
    type = "SystemAssigned"
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name                                   = "ipconfig"
      primary                                = true
      subnet_id                              = var.subnet_id
      load_balancer_backend_address_pool_ids = [var.backend_pool_id]
    }
  }

  boot_diagnostics {} # managed storage: serial console + screenshots for debugging

  # ---- Rolling upgrades ----------------------------------------------------
  upgrade_mode = "Rolling"

  rolling_upgrade_policy {
    # Surge: build NEW instances from the latest model, then delete old ones.
    # New instances run cloud-init fresh, so user removals take effect and
    # capacity never drops during a rollout.
    maximum_surge_instances_enabled         = true
    max_batch_instance_percent              = 50
    max_unhealthy_instance_percent          = 50
    max_unhealthy_upgraded_instance_percent = 0 # one bad new instance halts the rollout
    pause_time_between_batches              = "PT1M"
    prioritize_unhealthy_instances_enabled  = true
  }

  # The rollout only proceeds while new instances report healthy on /ready.
  extension {
    name                       = "HealthExtension"
    publisher                  = "Microsoft.ManagedServices"
    type                       = "ApplicationHealthLinux"
    type_handler_version       = "2.0"
    auto_upgrade_minor_version = true

    settings = jsonencode({
      protocol    = "http"
      port        = 80
      requestPath = "/ready"
    })
  }

  automatic_instance_repair {
    enabled      = true
    grace_period = "PT15M" # time for first boot: packages, image pull, secrets
  }

  tags = var.tags

  lifecycle {
    # Autoscale owns the instance count after creation.
    ignore_changes = [instances]
  }
}

# The instances read secrets with their own identity: no credentials on disk.
resource "azurerm_role_assignment" "vmss_secrets" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine_scale_set.this.identity[0].principal_id
}
