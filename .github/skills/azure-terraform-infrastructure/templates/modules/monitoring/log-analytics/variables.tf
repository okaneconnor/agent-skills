# =============================================================================
# Log Analytics Module Variables
# =============================================================================

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "location_short" {
  description = "Short name for the Azure region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "workspace_name" {
  description = "Name suffix for the Log Analytics workspace"
  type        = string
}

variable "sku" {
  description = "SKU of the Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Data retention in days (30-730)"
  type        = number
  default     = 30
}

variable "daily_quota_gb" {
  description = "Daily quota in GB (-1 for unlimited)"
  type        = number
  default     = -1
}

variable "internet_ingestion_enabled" {
  description = "Enable internet ingestion"
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Enable internet query"
  type        = bool
  default     = true
}

variable "solutions" {
  description = "List of Log Analytics solutions to deploy"
  type        = list(string)
  default = [
    "ContainerInsights",
    "VMInsights",
    "SecurityInsights",
    "AzureActivity"
  ]
}

variable "data_collection_rules" {
  description = "Data collection rules for Azure Monitor Agent"
  type = map(object({
    data_flows = list(object({
      streams = list(string)
    }))
    enable_syslog                   = optional(bool, false)
    syslog_facilities               = optional(list(string), ["*"])
    syslog_levels                   = optional(list(string), ["*"])
    enable_performance_counters     = optional(bool, false)
    perf_counter_sampling_frequency = optional(number, 60)
    perf_counter_specifiers         = optional(list(string), [])
  }))
  default = {}
}

variable "alert_rules" {
  description = "Scheduled query alert rules"
  type = map(object({
    description             = string
    enabled                 = optional(bool, true)
    severity                = number # 0-4
    evaluation_frequency    = string # PT5M, PT10M, etc.
    window_duration         = string # PT5M, PT10M, etc.
    query                   = string
    time_aggregation_method = string # Count, Average, Minimum, Maximum, Total
    threshold               = number
    operator                = string # Equal, GreaterThan, GreaterThanOrEqual, LessThan, LessThanOrEqual
    min_failing_periods     = optional(number, 1)
    evaluation_periods      = optional(number, 1)
    action_group_ids        = optional(list(string), [])
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
