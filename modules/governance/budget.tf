locals {
  # Alert on ACTUAL spend as it happens, and on the FORECAST so a runaway
  # cost is caught before the money is spent.
  budget_alerts = [
    { threshold = 50, type = "Actual" },
    { threshold = 80, type = "Actual" },
    { threshold = 100, type = "Actual" },
    { threshold = 100, type = "Forecasted" },
  ]
}

resource "azurerm_consumption_budget_resource_group" "this" {
  name              = "budget-${var.name_prefix}"
  resource_group_id = var.resource_group_id
  amount            = var.budget_amount
  time_grain        = "Monthly"

  time_period {
    # Budgets must start on the first of a month.
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }

  dynamic "notification" {
    for_each = local.budget_alerts
    content {
      enabled        = true
      threshold      = notification.value.threshold
      threshold_type = notification.value.type
      operator       = "GreaterThanOrEqualTo"
      contact_emails = var.budget_alert_emails
    }
  }

  lifecycle {
    # timestamp() changes every run; the start date only matters on creation.
    ignore_changes = [time_period]
  }
}
