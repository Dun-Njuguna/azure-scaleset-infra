# Run: terraform test   (from modules/users). No Azure credentials needed.

variables {
  environment = "dev"
  users = {
    alice = {
      ssh_keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGq0aTJNb7jSPxRZB8b2kEwz6c1nO8xFq3H7uYc0dL2m alice@laptop"]
      sudo         = true
      environments = ["dev", "staging", "prod"]
    }
    bob = {
      ssh_keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB4p9yF0vQ2kT8sL1mR7nX3cW6eH5jZ0aD9gU2iK4oPq bob@laptop"]
      sudo         = false
      environments = ["dev"]
    }
  }
}

run "dev_gets_both_users" {
  command = plan

  assert {
    condition     = output.usernames == tolist(["alice", "bob"])
    error_message = "dev should contain alice and bob."
  }
}

run "prod_only_gets_users_listed_for_prod" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = output.usernames == tolist(["alice"])
    error_message = "bob is not listed for prod and must not get an account."
  }
}

run "sudo_only_for_sudo_users" {
  command = plan

  assert {
    condition     = output.cloud_init_users[0].sudo == "ALL=(ALL) NOPASSWD:ALL"
    error_message = "alice should have sudo."
  }

  assert {
    condition     = !contains(keys(output.cloud_init_users[1]), "sudo")
    error_message = "bob must not have a sudo entry at all."
  }
}

run "passwords_are_always_locked" {
  command = plan

  assert {
    condition     = alltrue([for u in output.cloud_init_users : u.lock_passwd])
    error_message = "Every account must be key-only."
  }
}

run "rejects_rsa_keys" {
  command = plan

  variables {
    users = {
      carol = {
        ssh_keys     = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC carol@old-laptop"]
        sudo         = false
        environments = ["dev"]
      }
    }
  }

  expect_failures = [var.users]
}

run "rejects_reserved_usernames" {
  command = plan

  variables {
    users = {
      root = {
        ssh_keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGq0aTJNb7jSPxRZB8b2kEwz6c1nO8xFq3H7uYc0dL2m"]
        sudo         = true
        environments = ["dev"]
      }
    }
  }

  expect_failures = [var.users]
}

run "rejects_invalid_usernames" {
  command = plan

  variables {
    users = {
      "Dave.Smith" = {
        ssh_keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGq0aTJNb7jSPxRZB8b2kEwz6c1nO8xFq3H7uYc0dL2m"]
        sudo         = false
        environments = ["dev"]
      }
    }
  }

  expect_failures = [var.users]
}

run "rejects_unknown_environments" {
  command = plan

  variables {
    users = {
      erin = {
        ssh_keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGq0aTJNb7jSPxRZB8b2kEwz6c1nO8xFq3H7uYc0dL2m"]
        sudo         = false
        environments = ["qa"]
      }
    }
  }

  expect_failures = [var.users]
}

run "user_with_no_keys_is_rejected" {
  command = plan

  variables {
    users = {
      frank = {
        ssh_keys     = []
        sudo         = false
        environments = ["dev"]
      }
    }
  }

  expect_failures = [var.users]
}
