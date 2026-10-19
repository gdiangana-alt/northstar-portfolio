terraform {
  required_version = ">= 1.6.0"

  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_monitor_action_group" "front_door" {
  name                = "northstar-frontdoor-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "nsfrontdoor"

  email_receiver {
    name                    = "portfolio-operator"
    email_address           = var.alert_email_address
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_activity_log_alert" "front_door_endpoint_administrative_change" {
  name                = "northstar-frontdoor-endpoint-admin-change"
  resource_group_name = var.resource_group_name
  location            = "Global"
  scopes              = [var.front_door_endpoint_resource_id]

  criteria {
    category = "Administrative"
  }

  action {
    action_group_id = azurerm_monitor_action_group.front_door.id
  }
}
