# Pure logic: this module creates no Azure resources. It decides who gets an
# account in this environment and renders the cloud-init "users" entries.

locals {
  env_users = {
    for name, u in var.users : name => u
    if contains(u.environments, var.environment)
  }

  cloud_init_users = [
    for name in sort(keys(local.env_users)) : merge(
      {
        name                = name
        shell               = "/bin/bash"
        lock_passwd         = true # keys only, no password exists
        ssh_authorized_keys = local.env_users[name].ssh_keys
      },
      # sudo users can also run docker; others can log in and read logs only.
      local.env_users[name].sudo ? {
        groups = "sudo, docker"
        sudo   = "ALL=(ALL) NOPASSWD:ALL"
      } : {}
    )
  ]
}
