environment   = "dev"
address_space = "10.10.0.0/16"

# Compute: smallest that runs the app; off at night and weekends
vm_size                    = "Standard_B2s"
instances                  = { min = 1, max = 2, default = 1 }
autoscale_schedule_enabled = true
ssh_enabled                = true

postgres = {
  sku_name                     = "B_Standard_B1ms"
  storage_mb                   = 32768
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  high_availability_enabled    = false
}

# Redis can't be stopped (it bills 24/7), so it's off in dev by default.
redis = {
  enabled                   = false
  sku_name                  = "Balanced_B0"
  high_availability_enabled = false
}

budget_amount              = 30
lock_enabled               = false
key_vault_purge_protection = false
