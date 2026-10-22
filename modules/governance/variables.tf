variable "name_prefix" {
  type = string
}

variable "resource_group_id" {
  type = string
}

variable "budget_amount" {
  description = "Monthly budget for this environment, in the billing currency."
  type        = number

  validation {
    condition     = var.budget_amount > 0
    error_message = "budget_amount must be greater than zero."
  }
}

variable "budget_alert_emails" {
  description = "Who gets budget alerts."
  type        = list(string)

  validation {
    condition     = length(var.budget_alert_emails) > 0
    error_message = "Provide at least one email for budget alerts."
  }
}

variable "lock_enabled" {
  description = "Put a CanNotDelete lock on the resource group. Must be turned off before 'destroy'."
  type        = bool
}
