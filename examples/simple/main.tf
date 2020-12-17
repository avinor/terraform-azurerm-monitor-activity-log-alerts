module "simple" {
  source = "../../"

  name                = "simple"
  resource_group_name = "simple-rg"
  location            = "westeurope"

  short_name = "Short Name"

  emails = [
    {
      name                    = "sendtodevops"
      email_address           = "devops@contoso.com"
      use_common_alert_schema = true
    },
    {
      name                    = "sendtodevops2"
      email_address           = "devops2@contoso.com"
      use_common_alert_schema = true
    }
  ]

  webhooks = [
    {
      name                    = "callmyapiaswell"
      service_uri             = "http://example.com/alert"
      use_common_alert_schema = true
    },
    {
      name                    = "callmy2apiaswell"
      service_uri             = "http://example.com/alert2"
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