variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "dns_label" {
  description = "DNS label for the public IP: <label>.<region>.cloudapp.azure.com"
  type        = string
}

variable "health_path" {
  description = "HTTP path the probe checks. Instances only get traffic while it returns 200."
  type        = string
  default     = "/ready"
}

variable "ssh_enabled" {
  description = "Create the SSH NAT rule (ports 50000+ -> 22 on each instance)."
  type        = bool
}

variable "ssh_frontend_port_start" {
  type    = number
  default = 50000
}

variable "max_instances" {
  description = "Size of the SSH NAT port range: one port per possible instance."
  type        = number
}

variable "tags" {
  type = map(string)
}
