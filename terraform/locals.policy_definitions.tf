locals {
  policy_definition_dir    = "${path.module}/policy_definitions"
  policy_definition_suffix = ".alz_policy_definition.json"

  policy_definition_templates = {
    for f in fileset(local.policy_definition_dir, "*${local.policy_definition_suffix}") :
    trimsuffix(f, local.policy_definition_suffix) => replace(
      file("${local.policy_definition_dir}/${f}"),
      "/providers/Microsoft.Management/managementGroups/placeholder",
      local.template_vars.root_scope
    )
  }

  policy_definitions = {
    for key, template in local.policy_definition_templates :
    key => jsondecode(templatestring(template, local.template_vars))
  }

  policy_definition_ids = {
    for key, definition in local.policy_definitions :
    key => "${local.template_vars.root_scope}/providers/Microsoft.Authorization/policyDefinitions/${definition.name}"
  }
}