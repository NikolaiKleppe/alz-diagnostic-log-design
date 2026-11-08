resource "azapi_resource" "policy_set_definition" {
  for_each = local.policy_set_definitions

  type      = "Microsoft.Authorization/policySetDefinitions@2021-06-01"
  name      = each.value.name
  parent_id = local.template_vars.root_scope

  body = {
    properties = each.value.properties
  }

  depends_on = [azapi_resource.policy_definition]

  lifecycle {
    precondition {
      condition     = each.value.name == each.key
      error_message = "The name in ${each.key}${local.policy_set_definition_suffix} (${each.value.name}) must match the file name."
    }
  }
}
