# The whole cloud-config is built as an HCL object and rendered with
# yamlencode(), so there's no hand-written YAML indentation to get wrong.

locals {
  app_env_static = join("\n", compact([
    "APP_ENV=${var.environment}",
    "PORT=${var.app_port}",
    "PGHOST=${var.postgres_host}",
    "PGUSER=${var.postgres_user}",
    "PGDATABASE=${var.postgres_database}",
    "PGSSLMODE=require",
    "",
  ]))

  cloud_config = {
    # Create the docker group before users are added to it.
    groups = ["docker"]

    # "default" keeps the break-glass admin from the scale set's os profile;
    # everyone else comes from the users module.
    users = concat(["default"], var.cloud_init_users)

    ssh_pwauth      = false
    disable_root    = true
    package_update  = true
    package_upgrade = true
    packages        = ["docker.io", "jq", "curl", "unattended-upgrades", "postgresql-client"]

    write_files = [
      {
        path        = "/etc/app/app.env.static"
        permissions = "0600"
        content     = local.app_env_static
      },
      {
        path        = "/usr/local/bin/fetch-secrets.sh"
        permissions = "0750"
        content = templatefile("${path.module}/templates/fetch-secrets.sh.tftpl", {
          key_vault_name = var.key_vault_name
          redis_enabled  = var.redis_enabled
          redis_host     = coalesce(var.redis_host, "none")
        })
      },
      {
        path        = "/etc/systemd/system/app.service"
        permissions = "0644"
        content = templatefile("${path.module}/templates/app.service.tftpl", {
          app_image = var.app_image
          app_port  = var.app_port
        })
      },
      {
        # Admin access to Postgres: SSH in through Bastion, then run "sudo db".
        # The database only accepts connections from this subnet.
        path        = "/usr/local/bin/db"
        permissions = "0750"
        content     = <<-EOT
          #!/bin/sh
          # psql to this environment's Postgres, using the app's connection settings.
          set -a
          . /etc/app/app.env
          set +a
          exec psql "$@"
        EOT
      },
      {
        path        = "/etc/ssh/sshd_config.d/00-hardening.conf"
        permissions = "0644"
        content     = <<-EOT
          PermitRootLogin no
          PasswordAuthentication no
          KbdInteractiveAuthentication no
          MaxAuthTries 3
          X11Forwarding no
        EOT
      },
    ]

    runcmd = [
      ["systemctl", "enable", "--now", "docker"],
      ["systemctl", "daemon-reload"],
      ["systemctl", "enable", "--now", "app.service"],
      ["systemctl", "restart", "ssh"],
    ]
  }

  cloud_init = "#cloud-config\n${yamlencode(local.cloud_config)}"
}
