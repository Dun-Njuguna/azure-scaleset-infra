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
  description = "Source ranges allowed to SSH in (through the load balancer NAT rule)."
  type        = list(string)
}

variable "ssh_enabled" {
  description = "Open SSH from admin_cidrs."
  type        = bool
}

variable "tags" {
  type = map(string)
}
