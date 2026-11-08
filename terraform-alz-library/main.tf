data "azapi_client_config" "current" {}

locals {
  # The hierarchy is owned by the platform repository. The parent is the tenant root group, referenced by name.
  parent_resource_id = data.azapi_client_config.current.tenant_id

  # Library defaults (alz_policy_default_values.json) for the library assignments that the security repository takes over
  policy_default_values = {
    log_analytics_workspace_id = jsonencode({ value = var.security_workspace_id })
  }

  defender_sql_parameters = {
    workspaceRegion                         = jsonencode({ value = var.location })
    bringYourOwnDcr                         = jsonencode({ value = false })
    bringYourOwnUserAssignedManagedIdentity = jsonencode({ value = false })
  }
}

module "alz_security" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "~> 0.22"

  architecture_name  = var.architecture_name
  parent_resource_id = local.parent_resource_id
  location           = var.location

  policy_default_values = local.policy_default_values

  policy_assignments_to_modify = {
    (var.root_management_group_name) = {
      policy_assignments = {
        # Custom assignments are not covered by library defaults, so their parameters are set here
        Sec-Diag-AllLogs = {
          parameters = {
            logAnalytics = jsonencode({ value = var.security_workspace_id })
          }
        }
        Sec-MDFC-Config = {
          parameters = {
            logAnalytics                   = jsonencode({ value = var.security_workspace_id })
            emailSecurityContact           = jsonencode({ value = var.security_contact_email })
            ascExportResourceGroupName     = jsonencode({ value = var.mdfc_export_resource_group_name })
            ascExportResourceGroupLocation = jsonencode({ value = var.location })
          }
        }
      }
    }
    (var.platform_management_group_name) = {
      policy_assignments = {
        Deploy-MDFC-DefSQL-AMA = { parameters = local.defender_sql_parameters }
      }
    }
    (var.landing_zones_management_group_name) = {
      policy_assignments = {
        Deploy-MDFC-DefSQL-AMA = { parameters = local.defender_sql_parameters }
      }
    }
  }

  enable_telemetry = false
}
