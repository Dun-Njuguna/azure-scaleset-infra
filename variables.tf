# =============================================================================
# General
# =============================================================================
variable "project" {
  description = "Short project name used in resource names."
  type        = string
  default     = "plat"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,7}$", var.project))
    error_message = "project must be 2-8 lowercase letters/digits (it ends up in globally unique names)."
  }
}

variable "environment" {
  description = "Which environment this state builds."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "location" {
  description = "Azure region. South Africa North is the closest region to Nairobi."
  type        = string
  default     = "southafricanorth"
}

variable "owner" {
  description = "Tag: who owns this environment."
  type        = string
}

variable "cost_center" {
  description = "Tag: what budget this is charged to."
  type        = string
  default     = "platform"
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}

variable "alert_emails" {
  description = "Who receives monitoring, autoscale and budget alerts."
  type        = list(string)
}

# =============================================================================
# Network and access
# =============================================================================
variable "address_space" {
  description = "VNet /16. Use a different one per environment so they could be peered later."
  type        = string
}

variable "admin_cidrs" {
  description = "Your public IP(s): allowed to SSH in and through the Key Vault firewall."
  type        = list(string)

  validation {
    condition     = alltrue([for c in var.admin_cidrs : can(cidrhost(c, 0))])
    error_message = "admin_cidrs must be CIDRs, e.g. 203.0.113.10/32."
  }

  validation {
    condition     = !contains(var.admin_cidrs, "0.0.0.0/0")
    error_message = "Don't open admin access to the whole internet."
  }
}

variable "ssh_enabled" {
  description = "Allow SSH from admin_cidrs through the load balancer."
  type        = bool
}

# =============================================================================
# Users (shared across environments, see envs/common.tfvars)
# =============================================================================
variable "users" {
  description = "Linux users. See modules/users for the rules."
  type = map(object({
    ssh_keys     = list(string)
    sudo         = bool
    environments = list(string)
  }))
}

# =============================================================================
# Compute
# =============================================================================
variable "vm_size" {
  type = string
}

variable "instances" {
  description = "Scale set capacity."
  type = object({
    min     = number
    max     = number
    default = number
  })

  validation {
    condition     = var.instances.min <= var.instances.default && var.instances.default <= var.instances.max
    error_message = "instances must satisfy min <= default <= max."
  }
}

variable "zones" {
  type    = list(string)
  default = []
}

variable "app_image" {
  description = "Container image to run (from project 1). Changing it triggers a rolling upgrade."
  type        = string
}

variable "autoscale_schedule_enabled" {
  description = "Scale to zero on nights and weekends."
  type        = bool
}

# =============================================================================
# Data
# =============================================================================
variable "postgres" {
  type = object({
    sku_name                     = string
    storage_mb                   = number
    backup_retention_days        = number
    geo_redundant_backup_enabled = bool
    high_availability_enabled    = bool
  })
}

variable "postgres_password_version" {
  description = "Bump this number to rotate the Postgres password. The new password goes to Postgres and Key Vault together, and never into state."
  type        = number
  default     = 1
}

variable "redis" {
  type = object({
    enabled                   = bool
    sku_name                  = string
    high_availability_enabled = bool
  })
}

# =============================================================================
# Governance
# =============================================================================
variable "budget_amount" {
  description = "Monthly budget for this environment."
  type        = number
}

variable "lock_enabled" {
  description = "CanNotDelete lock on the resource group. Set false and apply before destroying."
  type        = bool
}

variable "key_vault_purge_protection" {
  type = bool
}
