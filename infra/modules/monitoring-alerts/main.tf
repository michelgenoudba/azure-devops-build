resource "azurerm_monitor_action_group" "this" {
  name                    = var.action_group_name
  resource_group_name     = var.resource_group_name
  short_name              = varaction_group_short_name

  email_receiver {
    name                  = "primary-maintainer"
    email_address         = var.notification_email
  }

  tags = var.tags
}

# 1. Page load latency (client-side, App Insights JS SDK).
# Baseline (30-day window, Sept 2026): p95 ~300-320ms, p99 ~320-370ms.
# Threshold set ~3x above the observed p95 to absorb normal variance while
# still catching a real regression. See ADR 0014.
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "latency" {
  name                      = "alert-latency-p95-high"
  resource_group_name       = var.resource_group_name
  location                  = var.location
  severity                  = 2
  scopes                    = var.log_analytics_workspace_id]
  evaluation_frequency      = "PT5M"
  window_duration           = "PT15M"
  enabled                   = true
  auto_mitigation_enabled   = true
  description               = "Page load p95 duration exceeded 1000ms(baseline ~300ms)."
  display_name              = "Latency: p95 page load > 1000ms"

  criteria {
    query = <<-KQL
      AppPageViews
      | where TimeGenerated > ago(15m)
      | summarize p95Duration = percentile(DurationMs, 95)
    QKL
    
    time_aggregation_method = "Average"
    threshold               = 1000
    operator                = "GreaterThan"
    
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.this.id]
  }

  tags = var.tags
}


#2. JS exceptions - baseline is 0, so any occurence is worth investigating.
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "js_exceptions" {
  name                        = "alert-js-exceptions"
  resource_group_name         = var.resource_group_name
  location                    = var.location
  severity                    = 3
  scopes                      = [var.log_analytics_workspace_id]
  evaluation_frequency        = "PT5M"
  window_duration             = "PT15M"
  enabled                     = true
  auto_mitigation_enabled     = true
  description                 = "One or mor client-side JS exceptions in the last 15 minutes (baseline is 0)."
  display_name                = "JS exceptions: any occurence"

  criteria {
    query = <<-KQL
      AppExceptions
      | where TimeGenerated > ago(15m)
      | summarize ExceptionCount = count()
    KQL

    time_aggregation_method = "Total"
    threshold               = 0
    operator                = "GreaterThan"

    failing periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.this.id]
  }

  tags = var.tags
}

#3. HTTP error rate at the nginx layer - baseline is a solid 0% across real
#traffic up to ~5,400 req/hour. Guarded with a minimum request count so a
#quiet window can't read as a misleading 100% rate.
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "http_error_rate" {
  name                 = "alert-http-error-rate"
  resource_group_name  = var.resource_group_name
  location             = var.location
  severity             = 1
  scopes               = [var.log_analytics_workspace_id]
  evaluation_frequency  = "PT5M"
  window_duration       = "PT15M"
  enabled               = true
  auto_mitigation_enabled = true
  description           = "Real (non-probe) HTTP 5xx error rate exceeded 5% (baseline is 0%). Requires at least 10 requests in the window to avoid noise on quiet periods."
  display_name          = "HTTP error rate > 5%"

  criteria {
    query = <<-KQL
      ContainerLog
      | where TimeGenerated > ago(15m)
      | where LogEntry matches regex @'HTTP/\d\.\d"\s\d{3}\s'
      | extend StatusCode = toint(extract(@'HTTP/\d\.\d"\s(\d{3})\s', 1, LogEntry))
      | extend IsProbe = LogEntry has "kube-probe"
      | where IsProbe == false
      | summarize TotalRequests = count(), ErrorRequests = countif(StatusCode >= 500)
      | where TotalRequests >= 10
      | extend ErrorRatePercent = round(100.0 * ErrorRequests / TotalRequests, 2)
      | project ErrorRatePercent
    KQL

    time_aggregation_method = "Average"
    threshold                = 5
    operator                 = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.this.id]
  }

  tags = var.tags
}

#4. Pod health - baseline is 2/2 Running, 0 restarts.
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "pod_health" {
  name                 = "alert-pod-not-running"
  resource_group_name  = var.resource_group_name
  location             = var.location
  severity             = 1
  scopes               = [var.log_analytics_workspace_id]
  evaluation_frequency  = "PT5M"
  window_duration       = "PT15M"
  enabled               = true
  auto_mitigation_enabled = true
  description           = "One or more app pods not in Running state in the last 15 minutes (baseline is 2/2 Running)."
  display_name          = "Pod health: pod not Running"

  criteria {
    query = <<-KQL
      KubePodInventory
      | where TimeGenerated > ago(15m)
      | where Namespace == "app"
      | summarize arg_max(TimeGenerated, PodStatus) by Name
      | where PodStatus != "Running"
      | count
    KQL

    time_aggregation_method = "Total"
    threshold                = 0
    operator                 = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.this.id]
  }

  tags = var.tags
}

#5. CPU / memory pressure on the static-site container. Thresholds are a 
#percentage of the Helm chart's own resource LIMITS (cpu: 200m,
#memory: 128Mi) - not the observed baseline (~1-4% o fthe much smaller
#request) - because limit-relative headroom is what predicts real
#throttling/00MKill risk regardless of current traffic. See ADR 0014.
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "resource_pressure" {
  name                 = "alert-container-resource-pressure"
  resource_group_name  = var.resource_group_name
  location             = var.location
  severity             = 2
  scopes               = [var.log_analytics_workspace_id]
  evaluation_frequency  = "PT5M"
  window_duration       = "PT15M"
  enabled               = true
  auto_mitigation_enabled = true
  description           = "CPU or memory usage exceeded 80% of the container's Helm-defined limit (cpu 200m / memory 128Mi). Observed baseline is only ~1-4% of the request (50m/32Mi)."
  display_name          = "Container CPU/Memory > 80% of limit"

  criteria {
    query = <<-KQL
      Perf
      | where TimeGenerated > ago(15m)
      | where ObjectName == "K8SContainer"
      | where InstanceName endswith "/static-site"
      | where CounterName in ("cpuUsageNanoCores", "memoryWorkingSetBytes")
      | summarize AvgValue = avg(CounterValue) by CounterName
      | extend PercentOfLimit = case(
          CounterName == "cpuUsageNanoCores", round(100.0 * AvgValue / 200000000, 2),
          CounterName == "memoryWorkingSetBytes", round(100.0 * AvgValue / 134217728, 2),
          real(null)
        )
      | summarize MaxPercentOfLimit = max(PercentOfLimit)
    KQL

    time_aggregation_method = "Average"
    threshold                = 80
    operator                 = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.this.id]
  }

  tags = var.tags
}