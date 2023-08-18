terraform {
  required_version = ">= 0.13"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.69.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_key_vault_secret" "kvs" {
  for_each = { for k, v in var.activity_log_alerts : k => v if v.action_group.logic_app.webhook.key_vault_id != null }

  name         = each.value.action_group.logic_app.webhook.uri
  key_vault_id = each.value.action_group.logic_app.webhook.key_vault_id
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

resource "azurerm_logic_app_workflow" "la" {
  for_each = { for k, v in var.activity_log_alerts : k => v if v.action_group.logic_app != null }

  name                = "${replace(each.key, "_", "-")}-la-workflow"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

resource "azurerm_logic_app_trigger_http_request" "request" {
  for_each = { for k, v in var.activity_log_alerts : k => v if v.action_group.logic_app != null }

  name         = "${replace(each.key, "_", "-")}-la-alert-trigger-http"
  logic_app_id = azurerm_logic_app_workflow.la[each.key].id

  schema = each.value.action_group.logic_app.http_trigger_schema
}

resource "azurerm_logic_app_action_http" "action" {
  for_each = { for k, v in var.activity_log_alerts : k => v if v.action_group.logic_app != null }

  name         = "${replace(each.key, "_", "-")}-la-action"
  logic_app_id = azurerm_logic_app_workflow.la[each.key].id
  method       = "POST"
  uri          = each.value.action_group.logic_app.webhook.key_vault_id == null ? each.value.action_group.logic_app.webhook.uri : data.azurerm_key_vault_secret.kvs[each.key].value
  body         = each.value.action_group.logic_app.webhook.body
  headers = {
    "Content-type" = "application/json"
  }
}

resource "azurerm_monitor_action_group" "main" {
  for_each = var.activity_log_alerts

  name                = "${each.value.action_group.name}-ag"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = substr(each.value.action_group.display_name, 0, 12)

  tags = var.tags

  dynamic "email_receiver" {
    for_each = each.value.action_group.email != null ? [true] : []
    content {
      name                    = each.value.action_group.email.name
      email_address           = each.value.action_group.email.address
      use_common_alert_schema = each.value.action_group.email.use_common_alert_schema
    }
  }

  dynamic "logic_app_receiver" {
    for_each = each.value.action_group.logic_app != null ? [true] : []
    content {
      name                    = "${replace(each.key, "_", "-")}-la-action"
      resource_id             = azurerm_logic_app_workflow.la[each.key].id
      callback_url            = azurerm_logic_app_trigger_http_request.request[each.key].callback_url
      use_common_alert_schema = true
    }
  }
}

resource "azurerm_monitor_activity_log_alert" "main" {
  for_each = var.activity_log_alerts

  tags = var.tags

  name                = replace(each.key, "_", "-")
  resource_group_name = azurerm_resource_group.main.name
  scopes              = each.value.scopes
  description         = each.value.description

  criteria {
    category = each.value.category
    dynamic "service_health" {
      for_each = each.value.category == "ServiceHealth" && each.value.regions != null ? [true] : []
      content {
        locations = each.value.regions
        events    = []
        services  = []
      }
    }
  }

  action {
    action_group_id    = azurerm_monitor_action_group.main[each.key].id
    webhook_properties = {}
  }
}
