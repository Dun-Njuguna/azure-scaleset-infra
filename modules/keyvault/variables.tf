variable "name" {
  description = "Globally unique vault name (3-24 chars)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.name))
    error_message = "Key Vault names are 3-24 characters: letters, digits and hyphens."
  }
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "purge_protection_enabled" {
  description = "Deleted secrets can't be purged early. Turn on for prod."
  type        = bool
}

variable "admin_cidrs" {
  description = "Public IPs allowed through the vault firewall (where Terraform runs)."
  type        = list(string)
}

variable "allowed_subnet_ids" {
  description = "Subnets (with the Microsoft.KeyVault service endpoint) allowed through the firewall."
  type        = list(string)
}

variable "deployer_object_id" {
  description = "Object ID of whoever runs Terraform; gets permission to write secrets."
  type        = string
}

variable "breakglass_private_key" {
  description = "Private SSH key of the emergency admin account."
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "Ephemeral: written once per version, never stored in state."
  type        = string
  ephemeral   = true
}

variable "postgres_password_version" {
  description = "Bump to rotate the Postgres password (Postgres and the vault update together)."
  type        = number
}

variable "redis_enabled" {
  type = bool
}

variable "redis_access_key" {
  type      = string
  sensitive = true
  default   = null
}

variable "tags" {
  type = map(string)
}
