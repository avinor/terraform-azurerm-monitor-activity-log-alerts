variables {
  resource_group_name = "simple-rg"
  location            = "westeurope"

  diagnostics = {
    destination   = "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/example-resource-group/providers/Microsoft.OperationalInsights/workspaces/workspaceValue"
    eventhub_name = null
    logs          = ["WorkflowRuntime"]
    metrics       = []
  }


  activity_log_alerts = {
    "recommendation" = {
      scopes      = ["557184c6-b112-49b6-8e79-230fe3aee4f0"]
      description = "My description"
      category    = "Recommendation"
      regions     = null
      action_group = {
        name         = "my-recommendations"
        display_name = "My Recommendations"
        email = {
          name                    = "sendtodevops"
          address                 = "devops@contoso.com"
          use_common_alert_schema = true
        }
        logic_app = {
          http_trigger_schema = <<-SCHEMA
          {
              "type": "object",
              "properties": {
                  "schemaId": {
                      "type": "string"
                  }
              }
          }
          SCHEMA
          webhook = {
            key_vault_id = null
            uri          = "https://example.com/alert"
            body         = <<-BODY
            {
              "msg": "This is an alert!"
            }
            BODY
          }
        }
      }
    },
    "service_health" = {
      scopes      = ["557184c6-b112-49b6-8e79-230fe3aee4f0"]
      description = "My description"
      category    = "ServiceHealth"
      regions     = ["North Europe", "West Europe"]
      action_group = {
        name         = "my-service-health"
        display_name = "My ServiceHealth"
        email        = null
        logic_app = {
          http_trigger_schema = <<-SCHEMA
          {
              "type": "object",
              "properties": {
                  "schemaId": {
                      "type": "string"
                  }
              }
          }
          SCHEMA
          webhook = {
            key_vault_id = null
            uri          = "https://example.com/alert2"
            body         = <<-BODY
            {
              "alert": true
            }
            BODY
          }
        }
      }
    },
  }
}
run "simple"{
  command = plan
}
run "test-logicapp-creation" {
  command = plan

  assert {
    condition     = azurerm_monitor_diagnostic_setting.logic_app_diagnostics["recommendation"].name == "recommendation-diagnostic-settings"
    error_message = " Name did not match expected"
  }
  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.logic_app_diagnostics) == 2
    error_message = " Length did not match expected"
  }
}
