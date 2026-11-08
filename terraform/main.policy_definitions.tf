resource "azapi_resource" "policy_definition" {
  for_each = local.policy_definitions

  type      = "Microsoft.Authorization/policyDefinitions@2021-06-01"
  name      = each.value.name
  parent_id = local.template_vars.root_scope

  body = {
    properties = each.value.properties
  }
}
