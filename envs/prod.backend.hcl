# From: cd bootstrap && terraform output backend_config
resource_group_name  = "rg-tfstate"
storage_account_name = "sttfstateCHANGEME"
container_name       = "tfstate"
key                  = "prod.tfstate"
use_azuread_auth     = true
