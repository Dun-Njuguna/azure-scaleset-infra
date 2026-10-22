# Shared by every environment. Per-environment values live in <env>.tfvars.
# Real values that shouldn't be committed (your IP, email) go in
# common.local.tfvars / <env>.local.tfvars: git-ignored, loaded last by scripts/tf.sh.

project     = "plat"
location    = "southafricanorth"
owner       = "duncan-kariuki"
cost_center = "platform"

alert_emails = ["alerts@example.com"]  # override in common.local.tfvars
admin_cidrs  = ["203.0.113.10/32"]      # override in common.local.tfvars (your public IP)

app_image = "ghcr.io/your-github-user/node-cicd-pipeline:latest"

# -----------------------------------------------------------------------------
# Linux users: the single source of truth for who can log in where.
# Remove someone here and apply: every instance is replaced and their account
# is gone. Keys must be ed25519.
# The keys below are EXAMPLES. Replace them with real public keys.
# -----------------------------------------------------------------------------
users = {
  duncan = {
    ssh_keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICYMDInuga1xdI1OzHooqAQB0M2/HeGjgafMxga5Vsar duncan@laptop"]
    sudo         = true
    environments = ["dev", "staging", "prod"]
  }

  dev1 = {
    ssh_keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPBGJbzQ5bvT+aYSsU9xT+y+Exmlr5My7UfKnNlr9eS4 dev1@laptop"]
    sudo         = false
    environments = ["dev", "staging"]
  }
}
