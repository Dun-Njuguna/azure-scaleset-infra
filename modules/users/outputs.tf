output "cloud_init_users" {
  description = "List for the cloud-init 'users' key (append after \"default\")."
  value       = local.cloud_init_users
}

output "usernames" {
  value = sort(keys(local.env_users))
}

output "summary" {
  description = "username => sudo, for this environment."
  value       = { for name, u in local.env_users : name => u.sudo }
}
