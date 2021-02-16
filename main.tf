terraform {
  required_version = ">= 0.12.6"
}

provider azurerm {
  version = "~> 2.45.1"
  features {}
}

locals {
  key_vaults = { for w in var.webhooks : w.service_uri => w.key_vault_id if w.key_vault_id != null}
}

data "azurerm_key_vault_secret" "kvs" {
  for_each = local.key_vaults
  name         = each.key
  key_vault_id = each.value
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
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

  dynamic "webhook_receiver" {
    for_each = var.webhooks
    content {
      name                    = webhook_receiver.value.name
      service_uri             = webhook_receiver.value.key_vault_id == null ? webhook_receiver.value.service_uri : data.azurerm_key_vault_secret.kvs[webhook_receiver.value.service_uri].value
      use_common_alert_schema = webhook_receiver.value.use_common_alert_schema
    }
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