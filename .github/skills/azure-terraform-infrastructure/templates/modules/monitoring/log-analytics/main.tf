# =============================================================================
# Log Analytics Workspace Module
# Creates Log Analytics workspace with solutions
# =============================================================================

resource "azurerm_log_analytics_workspace" "workspace" {
  name                       = "log-${var.workspace_name}-${var.environment}-${var.location_short}-001"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  sku                        = var.sku
  retention_in_days          = var.retention_in_days
  daily_quota_gb             = var.daily_quota_gb
  internet_ingestion_enabled = var.internet_ingestion_enabled
  internet_query_enabled     = var.internet_query_enabled

  tags = merge(var.tags, {
    Module = "log-analytics"
  })
}

# =============================================================================
# Log Analytics Solutions
# =============================================================================

resource "azurerm_log_analytics_solution" "solutions" {
  for_each = toset(var.solutions)

  solution_name         = each.value
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
  workspace_name        = azurerm_log_analytics_workspace.workspace.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/${each.value}"
  }

  tags = merge(var.tags, {
    Module = "log-analytics"
  })
}

# =============================================================================
# Data Collection Rules (for Azure Monitor Agent)
# =============================================================================

resource "azurerm_monitor_data_collection_rule" "dcr" {
  for_each = var.data_collection_rules

  name                = "dcr-${each.key}-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
      name                  = "log-analytics-destination"
    }
  }

  dynamic "data_flow" {
    for_each = each.value.data_flows

    content {
      streams      = data_flow.value.streams
      destinations = ["log-analytics-destination"]
    }
  }

  dynamic "data_sources" {
    for_each = each.value.enable_syslog ? [1] : []

    content {
      syslog {
        facility_names = each.value.syslog_facilities
        log_levels     = each.value.syslog_levels
        name           = "syslog-datasource"
        streams        = ["Microsoft-Syslog"]
      }
    }
  }

  dynamic "data_sources" {
    for_each = each.value.enable_performance_counters ? [1] : []

    content {
      performance_counter {
        name                          = "perf-counters"
        streams                       = ["Microsoft-Perf"]
        sampling_frequency_in_seconds = each.value.perf_counter_sampling_frequency
        counter_specifiers            = each.value.perf_counter_specifiers
      }
    }
  }

  tags = merge(var.tags, {
    Module = "log-analytics"
  })
}

# =============================================================================
# Alert Rules
# =============================================================================

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "alerts" {
  for_each = var.alert_rules

  name                = "alert-${each.key}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_log_analytics_workspace.workspace.id]
  description         = each.value.description
  enabled             = each.value.enabled
  severity            = each.value.severity

  evaluation_frequency = each.value.evaluation_frequency
  window_duration      = each.value.window_duration

  criteria {
    query                   = each.value.query
    time_aggregation_method = each.value.time_aggregation_method
    threshold               = each.value.threshold
    operator                = each.value.operator

    failing_periods {
      minimum_failing_periods_to_trigger_alert = each.value.min_failing_periods
      number_of_evaluation_periods             = each.value.evaluation_periods
    }
  }

  dynamic "action" {
    for_each = each.value.action_group_ids

    content {
      action_groups = [action.value]
    }
  }

  tags = merge(var.tags, {
    Module = "log-analytics"
  })
}
