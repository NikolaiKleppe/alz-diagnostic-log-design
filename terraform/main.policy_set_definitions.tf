resource "azapi_resource" "policy_set_definition" {
  for_each = local.policy_set_definitions

  type      = "Microsoft.Authorization/policySetDefinitions@2023-04-01"
  name      = each.value.name
  parent_id = local.template_vars.root_scope

  body = {
    properties = each.value.properties
  }

  depends_on = [azapi_resource.policy_definition]
}
