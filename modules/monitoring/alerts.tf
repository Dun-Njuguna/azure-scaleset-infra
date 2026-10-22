locals {
  alerts = {
    # The load balancer can't reach any healthy instance on /ready.
    "site-unhealthy" = {
      scope       = var.lb_id
      namespace   = "Microsoft.Network/loadBalancers"
      metric      = "DipAvailability"
      aggregation = "Average"
      operator    = "LessThan"
      threshold   = 100
      severity    = 1
      description = "Health probe availability below 100%: at least one instance is failing /ready."
    }
    "vmss-cpu-high" = {
      scope       = var.vmss_id
      namespace   = "Microsoft.Compute/virtualMachineScaleSets"
      metric      = "Percentage CPU"
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 85
      severity    = 2
      description = "Scale set CPU above 85% (autoscale may be at its maximum)."
    }
    "postgres-cpu-high" = {
      scope       = var.postgres_id
      namespace   = "Microsoft.DBforPostgreSQL/flexibleServers"
      metric      = "cpu_percent"
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 80
      severity    = 2
      description = "Postgres CPU above 80%."
    }
    "postgres-storage-high" = {
      scope       = var.postgres_id
      namespace   = "Microsoft.DBforPostgreSQL/flexibleServers"
      metric      = "storage_percent"
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 80
      severity    = 2
      description = "Postgres storage above 80% (auto-grow is on, but check why)."
    }
  }
}

resource "azurerm_monitor_metric_alert" "this" {
  for_each = local.alerts

  name                = "alert-${var.name_prefix}-${each.key}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value.scope]
  description         = each.value.description
  severity            = each.value.severity
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = each.value.namespace
    metric_name      = each.value.metric
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.email.id
  }
}
