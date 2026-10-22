variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "alert_emails" {
  type = list(string)
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "vmss_id" {
  type = string
}

variable "lb_id" {
  type = string
}

variable "postgres_id" {
  type = string
}

variable "tags" {
  type = map(string)
}
