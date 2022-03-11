terraform {
  required_version = ">= 0.13"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.98.0"
    }
  }
}

provider azurerm {
  features {}
}

data "azurerm_key_vault_secret" "kvs" {
  name         = var.webhook.service_uri
  key_vault_id = var.webhook.key_vault_id
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

resource "azurerm_logic_app_workflow" "la" {
  name                = "${var.name}-la-workflow"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

resource "azurerm_logic_app_trigger_http_request" "request" {
  name         = "${var.name}-la-alert-trigger-http"
  logic_app_id = azurerm_logic_app_workflow.la.id

  schema = <<SCHEMA
{
    "type": "object",
    "properties": {
        "schemaId": {
            "type": "string"
        },
        "data": {
            "type": "object",
            "properties": {
                "essentials": {
                    "type": "object",
                    "properties": {
                        "alertId": {
                            "type": "string"
                        },
                        "alertRule": {
                            "type": "string"
                        },
                        "severity": {
                            "type": "string"
                        },
                        "signalType": {
                            "type": "string"
                        },
                        "monitorCondition": {
                            "type": "string"
                        },
                        "monitoringService": {
                            "type": "string"
                        },
                        "alertTargetIDs": {
                            "type": "array",
                            "items": {
                                "type": "string"
                            }
                        },
                        "originAlertId": {
                            "type": "string"
                        },
                        "firedDateTime": {
                            "type": "string"
                        },
                        "resolvedDateTime": {
                            "type": "string"
                        },
                        "description": {
                            "type": "string"
                        },
                        "essentialsVersion": {
                            "type": "string"
                        },
                        "alertContextVersion": {
                            "type": "string"
                        }
                    }
                },
                "alertContext": {
                    "type": "object",
                    "properties": {}
                }
            }
        }
    }
}
SCHEMA

}

resource "azurerm_logic_app_action_http" "action" {
  name         = "${var.name}-la-action"
  logic_app_id = azurerm_logic_app_workflow.la.id
  method       = "POST"
  uri          = var.webhook.key_vault_id == null ? var.webhook.service_uri : data.azurerm_key_vault_secret.kvs.value
  headers = {
    "Content-type" = "application/json"
  }
  body = <<-BODY
  {
      "username": "AzureHealth - Activity Log Alert",
      "blocks": [
          {
              "type": "section",
              "text": {
                  "type": "mrkdwn",
                  "text": "New Activity Log Alert: https://portal.azure.com/#blade/Microsoft_Azure_Health/AzureHealthBrowseBlade/serviceIssues\n\nDetails:\nMonitoring Service: @{triggerBody()?['data']?['essentials']?['monitoringService']}\nMonitoring Condition: @{triggerBody()?['data']?['essentials']?['monitorCondition']}\nDescription: @{triggerBody()?['data']?['essentials']?['description']}\nSignal Type: @{triggerBody()?['data']?['essentials']?['signalType']}\nSeverity: @{triggerBody()?['data']?['essentials']?['severity']}\nAlert Rule: @{triggerBody()?['data']?['essentials']?['alertRule']}\nAlert ID: @{triggerBody()?['data']?['essentials']?['alertId']}\nAlert Target IDs: @{triggerBody()?['data']?['essentials']?['alertTargetIDs']}\n"
              }
          }
      ]
  }
  BODY
}

resource "azurerm_monitor_action_group" "main" {
  name                = "${var.name}-ag"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = var.short_name

  tags = var.tags

  dynamic "email_receiver" {
    for_each = var.emails
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }

  logic_app_receiver {
    name                    = "${var.name}-la-action"
    resource_id             = azurerm_logic_app_workflow.la.id
    callback_url            = azurerm_logic_app_trigger_http_request.request.callback_url
    use_common_alert_schema = true
  }

}

resource "azurerm_monitor_activity_log_alert" "main" {
  for_each = var.activity_log_alerts

  tags = var.tags

  name                = each.key
  resource_group_name = azurerm_resource_group.main.name
  scopes              = each.value.scopes
  description         = each.value.description

  criteria {
    category = each.value.criteria_category
    dynamic "service_health" {
      for_each = each.value.criteria_category == "ServiceHealth" && each.value.criteria_locations != null ? [true] : []
      content {
        locations = each.value.criteria_locations
      }
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}
