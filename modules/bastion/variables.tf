variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  description = "The AzureBastionSubnet."
  type        = string
}

variable "sku" {
  description = "Standard is needed for 'az network bastion ssh' from your terminal. Basic is browser-only (Azure portal)."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard or Premium."
  }
}

variable "tags" {
  type = map(string)
}
