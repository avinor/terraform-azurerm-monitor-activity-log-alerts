module "simple" {
  source = "../../"

  resource_group_name = "simple-rg"
  location            = "westeurope"

  activity_log_alerts = {
    "recommendation" = {
      scopes       = ["557184c6-b112-49b6-8e79-230fe3aee4f0"]
      description  = "My description"
      category     = "Recommendation"
      regions      = null
      action_group = {
        name         = "my-recommendations"
        display_name = "My Recommendations"
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
                  "schemaId": {
                      "type": "string"
                  }
              }
          }
          SCHEMA
          webhook             = {
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
      scopes       = ["557184c6-b112-49b6-8e79-230fe3aee4f0"]
      description  = "My description"
      category     = "ServiceHealth"
      regions      = ["North Europe", "West Europe"]
      action_group = {
        name         = "my-service-health"
        display_name = "My ServiceHealth"
        email        = null
        logic_app    = {
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
          webhook             = {
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
