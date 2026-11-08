locals {
  policy_set_definition_dir    = "${path.module}/policy_set_definitions"
  policy_set_definition_suffix = ".alz_policy_set_definition.json"

  policy_set_definition_templates = {
    for f in fileset(local.policy_set_definition_dir, "*${local.policy_set_definition_suffix}") :
    trimsuffix(f, local.policy_set_definition_suffix) => replace(
      file("${local.policy_set_definition_dir}/${f}"),
      "/providers/Microsoft.Management/managementGroups/placeholder",
      local.template_vars.root_scope
    )
  }

  policy_set_definitions = {
    for key, template in local.policy_set_definition_templates :
    key => jsondecode(templatestring(template, local.template_vars))
  }

  policy_set_definition_ids = {
    for key, definition in local.policy_set_definitions :
    key => "${local.template_vars.root_scope}/providers/Microsoft.Authorization/policySetDefinitions/${definition.name}"
  }
}