terraform {
  required_version = ">= 0.12.6"
}

provider azurerm {
  version = "~> 2.58.0"
  features {}
}

data "azurerm_key_vault_secret" "kvs" {
  name         = var.webhooks.service_uri
  key_vault_id = var.webhooks.key_vault_id
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
  "schemaId": "azureMonitorCommonAlertSchema",
  "data": {
    "essentials": {
      "alertId": "/subscriptions/<subscription ID>/providers/Microsoft.AlertsManagement/alerts/b9569717-bc32-442f-add5-83a997729330",
      "alertRule": "WCUS-R2-Gen2",
      "severity": "Sev3",
      "signalType": "Metric",
      "monitorCondition": "Resolved",
      "monitoringService": "Platform",
      "alertTargetIDs": [
        "/subscriptions/<subscription ID>/resourcegroups/pipelinealertrg/providers/microsoft.compute/virtualmachines/wcus-r2-gen2"
      ],
      "originAlertId": "3f2d4487-b0fc-4125-8bd5-7ad17384221e_PipeLineAlertRG_microsoft.insights_metricAlerts_WCUS-R2-Gen2_-117781227",
      "firedDateTime": "2019-03-22T13:58:24.3713213Z",
      "resolvedDateTime": "2019-03-22T14:03:16.2246313Z",
      "description": "",
      "essentialsVersion": "1.0",
      "alertContextVersion": "1.0"
    },
    "alertContext": {
      "properties": null,
      "conditionType": "SingleResourceMultipleMetricCriteria",
      "condition": {
        "windowSize": "PT5M",
        "allOf": [
          {
            "metricName": "Percentage CPU",
            "metricNamespace": "Microsoft.Compute/virtualMachines",
            "operator": "GreaterThan",
            "threshold": "25",
            "timeAggregation": "Average",
            "dimensions": [
              {
                "name": "ResourceId",
                "value": "3efad9dc-3d50-4eac-9c87-8b3fd6f97e4e"
              }
            ],
            "metricValue": 7.727
          }
        ]
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
  uri          = var.webhooks.key_vault_id == null ? var.webhooks.service_uri : data.azurerm_key_vault_secret.kvs.value
  headers = {
    "Content-type" = "application/json"
  }
  body = "{\"text\": \"A new message from Azure Service Health. Go to https://portal.azure.com/#blade/Microsoft_Azure_Health/AzureHealthBrowseBlade/serviceIssues\""
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
    resource_id             = var.logic_app
    callback_url            = azurerm_logic_app_workflow.la.access_endpoint
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
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}