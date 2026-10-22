variable "name_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "backend_pool_id" {
  type = string
}

variable "vm_size" {
  type = string
}

variable "os_disk_type" {
  type    = string
  default = "StandardSSD_LRS"
}

variable "zones" {
  description = "Availability zones to spread instances across. Empty = regional."
  type        = list(string)
  default     = []
}

variable "instances_min" {
  type = number
}

variable "instances_max" {
  type = number
}

variable "instances_default" {
  type = number

  validation {
    condition     = var.instances_default >= 1
    error_message = "instances_default must be at least 1 (use the night schedule to scale to zero)."
  }
}

variable "admin_username" {
  description = "Break-glass admin. Its private key lives only in Key Vault."
  type        = string
}

variable "admin_public_key" {
  type = string
}

variable "cloud_init_users" {
  description = "Output of the users module."
  type        = any
}

variable "app_image" {
  description = "Container image to run. Changing it rolls out a new version."
  type        = string
}

variable "app_port" {
  description = "Port the container listens on (published as 80 on the host)."
  type        = number
  default     = 3000
}

variable "key_vault_id" {
  type = string
}

variable "key_vault_name" {
  type = string
}

variable "postgres_host" {
  type = string
}

variable "postgres_user" {
  type = string
}

variable "postgres_database" {
  type = string
}

variable "redis_enabled" {
  type = bool
}

variable "redis_host" {
  type    = string
  default = null
}

variable "autoscale_schedule_enabled" {
  description = "Scale to zero outside business hours (nights and weekends)."
  type        = bool
}

variable "schedule_timezone" {
  type    = string
  default = "E. Africa Standard Time"
}

variable "business_hours" {
  description = "Hours (24h) when the schedule scales up and down."
  type = object({
    start = number
    end   = number
  })
  default = { start = 7, end = 20 }
}

variable "alert_emails" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}
