# Monitor Alert


This module deploys an azure monitor action group and activity log alerts.

Support for webhook and email revivers.

## Usage

To create a monitor action group deployed with [tau](https://github.com/avinor/tau).

```terraform
module {
  source = "github.com/avinor/terraform-azurerm-montor-action-group"
}

inputs {
  name                = "simple"
  resource_group_name = "actiongroup-rg"
  location            = "westeurope"
  short_name          = "Short Name"

  webhooks = [
    {  
      name                    = "myalert"
      service_uri             = "https://examples.com"
      use_common_alert_schema = true
    },
  ]

  activity_log_alerts = {
    "myname" = {
      scopes            = ["557184c6-b112-49b6-8e79-230fe3aee4f0"]
      description       = "My description"
      criteria_category = "Recommendation"
    },
  }
}
```
