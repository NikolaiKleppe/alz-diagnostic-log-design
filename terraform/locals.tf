locals {
  policy_assignment_dir        = "${path.module}/policy_assignments"
  policy_assignment_suffix     = ".alz_policy_assignment.json"
  policy_definition_dir        = "${path.module}/policy_definitions"
  policy_definition_suffix     = ".alz_policy_definition.json"
  policy_set_definition_dir    = "${path.module}/policy_set_definitions"
  policy_set_definition_suffix = ".alz_policy_set_definition.json"

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
  external_assigned_definition_ids = [
    for id in local.assigned_definition_ids : id
    if !contains(concat(values(local.policy_definition_ids), values(local.policy_set_definition_ids)), id)
  ]

  # Include members from both existing initiatives and local policy set definitions.
  member_definition_ids = distinct(compact(flatten(concat(
    [for d in data.azapi_resource.assigned_definition : try(tolist(d.output.members), [])],
    [for definition in values(local.policy_set_definitions) : [
      for member in definition.properties.policyDefinitions : member.policyDefinitionId
    ]]
  ))))
  external_member_definition_ids = [
    for id in local.member_definition_ids : id
    if !contains(values(local.policy_definition_ids), id)
  ]

  assigned_definition_roles = merge(
    {
      for id, d in data.azapi_resource.assigned_definition :
      id => try(tolist(d.output.roles), [])
    },
    {
      for key, definition in local.policy_definitions :
      local.policy_definition_ids[key] => try(tolist(definition.properties.policyRule.then.details.roleDefinitionIds), [])
    }
  )

  assigned_definition_members = merge(
    {
      for id, d in data.azapi_resource.assigned_definition :
      id => try(tolist(d.output.members), [])
    },
    {
      for key, definition in local.policy_set_definitions :
      local.policy_set_definition_ids[key] => [
        for member in definition.properties.policyDefinitions : member.policyDefinitionId
      ]
    }
  )

  member_definition_roles = merge(
    {
      for id, d in data.azapi_resource.member_definition :
      id => try(tolist(d.output.roles), [])
    },
    {
      for key, definition in local.policy_definitions :
      local.policy_definition_ids[key] => try(tolist(definition.properties.policyRule.then.details.roleDefinitionIds), [])
    }
  )

  # Roles required by the definition itself, or by all members for an initiative.
  definition_role_guids = {
    for id in local.assigned_definition_ids : id => distinct([
      for r in concat(
        try(local.assigned_definition_roles[id], []),
        flatten([
          for member_id in try(local.assigned_definition_members[id], []) :
          try(local.member_definition_roles[member_id], [])
        ])
      ) : lower(regex("[^/]+$", r))
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
