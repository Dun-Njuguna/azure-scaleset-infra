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

variable "tags" {
  type = map(string)
}
