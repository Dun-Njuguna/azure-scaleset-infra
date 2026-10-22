variable "name" {
  description = "Globally unique cache name."
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "sku_name" {
  description = "Azure Managed Redis SKU, e.g. Balanced_B0 (smallest) or Balanced_B1."
  type        = string
  default     = "Balanced_B0"
}

variable "high_availability_enabled" {
  description = "Replicated (two nodes). Off halves the cost; fine outside prod."
  type        = bool
}

variable "subnet_id" {
  description = "Subnet for the private endpoint."
  type        = string
}

variable "private_dns_zone_id" {
  type = string
}

variable "tags" {
  type = map(string)
}
