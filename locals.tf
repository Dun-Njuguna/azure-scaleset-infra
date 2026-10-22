locals {
  # Naming: <type>-<project>-<env>[-<suffix>]
  name_prefix = "${var.project}-${var.environment}"

  # Some names are global across Azure, so they get a short stable suffix.
  unique = random_string.suffix.result

  admin_username = "platformadmin"

  tags = merge(var.extra_tags, {
    project     = var.project
    environment = var.environment
    owner       = var.owner
    cost-center = var.cost_center
    managed-by  = "terraform"
  })
}
