variable "name_prefix" {
  description = "Prefix for resource names, e.g. plat-dev."
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "address_space" {
  description = "VNet CIDR. Must be a /16; subnets are carved out as /24s."
  type        = string

  validation {
    condition     = can(cidrhost(var.address_space, 0)) && endswith(var.address_space, "/16")
    error_message = "address_space must be a valid /16 CIDR, e.g. 10.10.0.0/16."
  }
}

variable "admin_cidrs" {
  description = "Public IPs allowed to reach Azure Bastion (HTTPS 443). Nothing else can start an SSH session."
  type        = list(string)
}

variable "bastion_enabled" {
  description = "Create AzureBastionSubnet. SSH to the app servers is only possible from this subnet."
  type        = bool
}

variable "tags" {
  type = map(string)
}
