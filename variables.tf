variable "resource_group_name" {
  description = "Name of resource group to deploy resources in."
}

variable "location" {
  description = "The Azure Region in which to create resource."
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default     = {}
}

variable "diagnostics" {
  description = "Diagnostic settings for those resources that support it. See README.md for details on configuration."
  type = object({
    destination   = string
    eventhub_name = optional(string)
    logs          = list(string)
    metrics       = list(string)
  })
  default = null
}

variable "activity_log_alerts" {
  description = "Map of activity log alerts"
  type = map(object({
    scopes      = list(string)
    description = string
    category    = string
    regions     = list(string)
    action_group = object({
      name         = string
      display_name = string
      logic_app = object({
        http_trigger_schema = string
        webhook = object({
          key_vault_id = string
          uri          = string
          body         = string
        })
      })
      email = object({
        name                    = string
        address                 = string
        use_common_alert_schema = bool
      })
    })
  }))
  default = null
}
