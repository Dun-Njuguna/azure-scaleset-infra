environment   = "staging"
address_space = "10.20.0.0/16"

vm_size                    = "Standard_B2s"
instances                  = { min = 1, max = 3, default = 1 }
autoscale_schedule_enabled = true
# Enable when needed, disable after (bills hourly).
bastion = {
  enabled = false
  sku     = "Standard"
}

postgres = {
  sku_name                     = "B_Standard_B1ms"
  storage_mb                   = 32768
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  high_availability_enabled    = false
}

redis = {
  enabled                   = true
  sku_name                  = "Balanced_B0"
  high_availability_enabled = false
}

budget_amount              = 60
lock_enabled               = false
key_vault_purge_protection = false
