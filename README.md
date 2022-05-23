# Activity log alerts

This module deploys one or
more [Activity log alert(s)](https://docs.microsoft.com/en-us/azure/azure-monitor/alerts/activity-log-alerts)
that uses [action group(s)](https://docs.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups) to trigger a
webhook via [Logic Apps](https://docs.microsoft.com/en-us/azure/connectors/connectors-native-http) and/or to send an
email.

## Example use case

Send a slack message and an email when a ServiceHealth Activity log alert is triggered

```terraform
module {
  source = "github.com/avinor/terraform-azurerm-monitor-activity-log-alerts"
}

inputs {
  resource_group_name = "simple-rg"
  location            = "westeurope"

  activity_log_alerts = {
    "service_health" = {
      scopes       = ["557184c6-b112-49b6-8e79-230fe3aee4f0"]
      description  = "My description"
      category     = "ServiceHealth"
      regions      = ["North Europe", "West Europe"]
      action_group = {
        name         = "my-service-health"
        display_name = "My ServiceHealth"
        email        = {
          name                    = "sendtodevops"
          address                 = "devops@contoso.com"
          use_common_alert_schema = true
        }
        logic_app = {
          http_trigger_schema = <<-SCHEMA
          {
              "type": "object",
              "properties": {
                  "data": {
                      "type": "object",
                      "properties": {
                          "alertContext": {
                              "type": "object",
                              "properties": {
                                  "properties": {
                                      "type": "object",
                                      "properties": {
                                          "trackingId": {
                                              "type": "string"
                                          }
                                      }
                                  }
                              }
                          }
                      }
                  }
              }
          }
          SCHEMA
          webhook             = {
            key_vault_id = null
            uri          = "https://my-slack-webhook"
            body         = <<-BODY
            {
                "username": "ServiceHealth",
                "blocks": [
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": "Resource Link: https://app.azure.com/h/@{triggerBody()?['data']?['alertContext']?['properties']?['trackingId']}\n"
                        }
                    }
                ]
            }
            BODY
          }
        }
      }
    },
  }
}
```

## Argument reference
The following arguments are supported:
* `resource_group_name` - (Required) Name of resource group to deploy resources in.
* `location` - (Required) The Azure Region in which to create resource.
* `tags` - (Optional) Tags to apply to all resources created.
* `activity_log_alerts` - (Required) A [activity_log_alerts]() block as defined below

### `activity_log_alerts` supports the following:
* `scopes` - (Required) The Scope at which the Activity Log should be applied, for example the Resource ID of a Subscription or a Resource (such as a Storage Account).
* `description` - (Optional) The description of the activity log alert.
* `category` - (Required) The category of the operation. Possible values are `Administrative`, `Autoscale`, `Policy`, `Recommendation`, `ResourceHealth`, `Security` and `ServiceHealth`. 
* `regions` -  (Optional) Locations this alert will monitor. For example, `West Europe`. Defaults to `Global`.
* `action_group.name` - (Required) The name of the Action Group.
* `action_group.display_name` - (Required) The short name of the action group. Max 12 characters.
* `action_group.logic_app.http_trigger_schema` - (Required) A JSON Blob defining the Schema of the incoming request. This needs to be valid JSON.
* `action_group.logic_app.webhook.key_vault_id` - (Optional) Resource URI of Key Vault that contains webhook. If set, `action_group.logic_app.webhook.uri` should refer to a secret within the Key Vault.  
* `action_group.logic_app.webhook.uri` - (Required) A Key Vault secret containing a webhook if `action_group.logic_app.webhook.key_vault_id` is set or simply an uri if `action_group.logic_app.webhook.key_vault_id` is null.   
* `action_group.logic_app.webhook.body` - (Required) Specifies the HTTP Body that should be sent to the uri when the uri is triggered.  
* `action_group.email.name` - (Optional) Name of email receiver.
* `action_group.email.address` - (Optional) Email address of email receiver.
* `action_group.email.use_common_alert_schema` - (Optional) Enables or disables the common alert schema.

## References
* [Activity log alerts](https://docs.microsoft.com/en-us/azure/azure-monitor/alerts/activity-log-alerts)
* [Action groups](https://docs.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups)
* [Trigger Logic Apps using action groups](https://docs.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups-logic-app)
