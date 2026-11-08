locals {
  template_vars = {
    default_location                = var.default_location
    root_scope                      = "/providers/Microsoft.Management/managementGroups/${var.root_management_group_id}"
    platform_scope                  = "/providers/Microsoft.Management/managementGroups/${var.platform_management_group_id}"
    landing_zones_scope             = "/providers/Microsoft.Management/managementGroups/${var.landing_zones_management_group_id}"
    security_workspace_id           = var.security_workspace_id
    security_contact_email          = var.security_contact_email
    mdfc_export_resource_group_name = var.mdfc_export_resource_group_name
  }
}
# 