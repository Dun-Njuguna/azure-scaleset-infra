locals {
  weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

  cpu_rules = [
    { direction = "Increase", operator = "GreaterThan", threshold = 70, window = "PT5M", cooldown = "PT5M" },
    { direction = "Decrease", operator = "LessThan", threshold = 25, window = "PT10M", cooldown = "PT10M" },
  ]

  # Normal capacity + CPU rules. Used all the time when the schedule is off,
  # and during business hours when it's on.
  normal_profile = {
    min = var.instances_min
    max = var.instances_max
    def = var.instances_default
  }
}

resource "azurerm_monitor_autoscale_setting" "this" {
  name                = "autoscale-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.this.id
  tags                = var.tags

  # ---- Default profile: CPU-based scaling ----------------------------------
  profile {
    name = "default"

    capacity {
      minimum = local.normal_profile.min
      maximum = local.normal_profile.max
      default = local.normal_profile.def
    }

    dynamic "rule" {
      for_each = local.cpu_rules
      content {
        metric_trigger {
          metric_name        = "Percentage CPU"
          metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
          time_grain         = "PT1M"
          statistic          = "Average"
          time_window        = rule.value.window
          time_aggregation   = "Average"
          operator           = rule.value.operator
          threshold          = rule.value.threshold
        }

        scale_action {
          direction = rule.value.direction
          type      = "ChangeCount"
          value     = "1"
          cooldown  = rule.value.cooldown
        }
      }
    }
  }

  # ---- Schedule: business hours up, nights and weekends at zero ------------
  # Azure recurrence profiles have a start time only; each one lasts until the
  # next begins. So "up" at 07:00 Mon-Fri and "zero" at 20:00 Mon-Fri covers
  # weekends too: Friday 20:00 lasts until Monday 07:00.
  dynamic "profile" {
    for_each = var.autoscale_schedule_enabled ? [1] : []
    content {
      name = "business-hours"

      capacity {
        minimum = local.normal_profile.min
        maximum = local.normal_profile.max
        default = local.normal_profile.def
      }

      recurrence {
        timezone = var.schedule_timezone
        days     = local.weekdays
        hours    = [var.business_hours.start]
        minutes  = [0]
      }

      dynamic "rule" {
        for_each = local.cpu_rules
        content {
          metric_trigger {
            metric_name        = "Percentage CPU"
            metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
            time_grain         = "PT1M"
            statistic          = "Average"
            time_window        = rule.value.window
            time_aggregation   = "Average"
            operator           = rule.value.operator
            threshold          = rule.value.threshold
          }

          scale_action {
            direction = rule.value.direction
            type      = "ChangeCount"
            value     = "1"
            cooldown  = rule.value.cooldown
          }
        }
      }
    }
  }

  dynamic "profile" {
    for_each = var.autoscale_schedule_enabled ? [1] : []
    content {
      name = "off-hours"

      capacity {
        minimum = 0
        maximum = 0
        default = 0
      }

      recurrence {
        timezone = var.schedule_timezone
        days     = local.weekdays
        hours    = [var.business_hours.end]
        minutes  = [0]
      }
    }
  }

  notification {
    email {
      custom_emails = var.alert_emails
    }
  }
}
