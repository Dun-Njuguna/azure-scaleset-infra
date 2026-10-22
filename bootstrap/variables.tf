variable "location" {
  description = "Azure region for the state storage."
  type        = string
  default     = "southafricanorth"
}

variable "resource_group_name" {
  description = "Resource group that holds the Terraform state storage."
  type        = string
  default     = "rg-tfstate"
}

variable "container_name" {
  description = "Blob container for state files (one blob per environment)."
  type        = string
  default     = "tfstate"
}
