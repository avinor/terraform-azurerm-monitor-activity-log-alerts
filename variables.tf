variable "name" {
  description = "The name of the Action Group."
}

variable "resource_group_name" {
  description = "Name of resource group to deploy resources in."
}

variable "location" {
  description = "The Azure Region in which to create resource."
}

variable "short_name" {
  description = "The short name of the action group. This will be used in SMS messages."
}

variable "enabled" {
  description = "Whether this action group is enabled. If an action group is not enabled, then none of its receivers will receive communications. Defaults to true."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default     = {}
}


variable "emails" {
  description = "List of email receivers"
  type = list(object({
    name                    = string
    email_address           = string
    use_common_alert_schema = bool
  }))
  default = []
}

variable "webhooks" {
  description = "List of webhook receivers"
  type = list(object({
    name                    = string
    service_uri             = string
    use_common_alert_schema = bool
  }))
  default = []
}

variable "activity_log_alerts" {
  description = "Map of acivity log alerts"
  type = map(object({
    scopes            = list(string)
    description       = string
    criteria_category = string
  }))
  default = null
}
