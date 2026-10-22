environment   = "prod"
address_space = "10.30.0.0/16"

# Compute: spread over zones, always on, autoscale on CPU
vm_size                    = "Standard_D2as_v5"
instances                  = { min = 2, max = 6, default = 2 }
zones                      = ["1", "2", "3"]
autoscale_schedule_enabled = false
ssh_enabled                = false # open temporarily via tfvars if ever needed

postgres = {
  sku_name                     = "GP_Standard_D2ds_v5"
  storage_mb                   = 65536
  backup_retention_days        = 35
  geo_redundant_backup_enabled = true
  high_availability_enabled    = true
}

redis = {
  enabled                   = true
  sku_name                  = "Balanced_B1"
  high_availability_enabled = true
}

budget_amount              = 400
lock_enabled               = true # set false and apply before any destroy
key_vault_purge_protection = true
