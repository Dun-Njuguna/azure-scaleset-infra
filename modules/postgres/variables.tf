variable "name" {
  description = "Globally unique server name."
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "delegated_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  type = string
}

variable "postgres_version" {
  type    = string
  default = "17"
}

variable "sku_name" {
  description = "e.g. B_Standard_B1ms (burstable) or GP_Standard_D2ds_v5 (general purpose)."
  type        = string
}

variable "storage_mb" {
  type    = number
  default = 32768
}

variable "backup_retention_days" {
  type = number

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 7 and 35."
  }
}

variable "geo_redundant_backup_enabled" {
  type = bool
}

variable "high_availability_enabled" {
  description = "Zone-redundant standby. Needs a General Purpose SKU and a region with zones."
  type        = bool
}

variable "administrator_login" {
  type    = string
  default = "pgadmin"
}

variable "administrator_password" {
  description = "Ephemeral: sent to Azure, never stored in state."
  type        = string
  ephemeral   = true
}

variable "administrator_password_version" {
  description = "Bump to apply a new password."
  type        = number
}

variable "databases" {
  type    = list(string)
  default = ["app"]
}

variable "tags" {
  type = map(string)
}
