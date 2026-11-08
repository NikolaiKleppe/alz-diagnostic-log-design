locals {
  policy_assignment_dir    = "${path.module}/policy_assignments"
  policy_assignment_suffix = ".alz_policy_assignment.json"

  # Tokens that can be used in the JSON files as ${token}
  template_vars = {
    default_location                = var.default_location
    root_scope                      = "/providers/Microsoft.Management/managementGroups/${var.root_management_group_id}"
    platform_scope                  = "/providers/Microsoft.Management/managementGroups/${var.platform_management_group_id}"
    landing_zones_scope             = "/providers/Microsoft.Management/managementGroups/${var.landing_zones_management_group_id}"
    security_workspace_id           = var.security_workspace_id
    security_contact_email          = var.security_contact_email
    mdfc_export_resource_group_name = var.mdfc_export_resource_group_name
  }

  # Raw file content is read separately because templatestring() does not accept a function call as its template
  policy_assignment_templates = {
    for f in fileset(local.policy_assignment_dir, "*${local.policy_assignment_suffix}") :
    trimsuffix(f, local.policy_assignment_suffix) => file("${local.policy_assignment_dir}/${f}")
  }

  raw_policy_assignments = {
    for key, template in local.policy_assignment_templates :
    key => jsondecode(templatestring(template, local.template_vars))
  }

  policy_assignments = {
    for key, assignment in local.raw_policy_assignments :
    key => merge(assignment, {
      properties = merge(assignment.properties, {
        policyDefinitionId = replace(
          assignment.properties.policyDefinitionId,
          "/providers/Microsoft.Management/managementGroups/placeholder",
          local.template_vars.root_scope
        )
      })
    })
  }

  assigned_definition_ids = distinct([for pa in local.policy_assignments : pa.properties.policyDefinitionId])

  # Member policy definitions of the assigned initiatives. concat() turns a missing (null) output into an empty list
  member_definition_ids = distinct(compact(flatten([
    for d in data.azapi_resource.assigned_definition : try(concat(d.output.members), [])
  ])))

  # Roles required by the definition itself, or by all members for an initiative
  definition_role_guids = {
    for id, d in data.azapi_resource.assigned_definition : id => distinct([
      for r in compact(flatten([
        try(concat(d.output.roles), []),
        [for m in compact(try(concat(d.output.members), [])) : try(concat(data.azapi_resource.member_definition[m].output.roles), [])]
      ])) : lower(regex("[^/]+$", r))
    ])
  }

  # One role assignment per role required by the assigned definition, at the scope of the assignment
  role_assignments = merge([
    for key, pa in local.policy_assignments : {
      for guid in local.definition_role_guids[pa.properties.policyDefinitionId] :
      "${key}/${guid}" => {
        assignment_key     = key
        scope              = pa.properties.scope
        role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/${guid}"
      }
    }
  ]...)
}
