variable "environment" {
  description = "Environment being built; only users who list it get an account."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "users" {
  description = <<-EOT
    Linux users, keyed by username. Each user lists the environments they may
    log in to. Remove a user here and apply: every instance is replaced and the
    account no longer exists anywhere.
  EOT
  type = map(object({
    ssh_keys     = list(string)
    sudo         = bool
    environments = list(string)
  }))

  validation {
    condition     = alltrue([for name, _ in var.users : can(regex("^[a-z_][a-z0-9_-]{0,31}$", name))])
    error_message = "Usernames must be lowercase Linux names: start with a letter or _, then letters, digits, _ or -, max 32 characters."
  }

  validation {
    condition = alltrue([for name, _ in var.users : !contains(
      ["root", "admin", "daemon", "bin", "sys", "sync", "nobody", "ubuntu", "azureuser", "platformadmin", "docker"],
      name
    )])
    error_message = "That username is reserved (system account or the break-glass admin)."
  }

  validation {
    condition     = alltrue([for _, u in var.users : length(u.ssh_keys) > 0])
    error_message = "Every user needs at least one SSH key."
  }

  validation {
    condition = alltrue(flatten([
      for _, u in var.users : [for k in u.ssh_keys : can(regex("^ssh-ed25519 [A-Za-z0-9+/]{68}( .*)?$", k))]
    ]))
    error_message = "Only ed25519 public keys are accepted (ssh-ed25519 AAAA... comment). Generate one with: ssh-keygen -t ed25519"
  }

  validation {
    condition = alltrue(flatten([
      for _, u in var.users : [for e in u.environments : contains(["dev", "staging", "prod"], e)]
    ]))
    error_message = "environments may only contain dev, staging or prod."
  }
}
