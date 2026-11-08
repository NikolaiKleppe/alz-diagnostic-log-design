locals {
  policy_assignment_dir    = "${path.module}/policy_assignments"
  policy_assignment_suffix = ".alz_policy_assignment.json"

  # Raw file content is read separately because templatestring() does not accept a function call as its template.
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
  external_assigned_definition_ids = [
    for id in local.assigned_definition_ids : id
    if !contains(concat(values(local.policy_definition_ids), values(local.policy_set_definition_ids)), id)
  ]

  # Include members from both existing initiatives and local policy set definitions.
  member_definition_ids = distinct(compact(concat(
    flatten([
      for d in data.azapi_resource.assigned_definition :
      try(flatten(d.output.members), [])
    ]),
    flatten([
      for definition in values(local.policy_set_definitions) : [
        for member in definition.properties.policyDefinitions : member.policyDefinitionId
      ]
    ])
  )))
  external_member_definition_ids = [
    for id in local.member_definition_ids : id
    if !contains(values(local.policy_definition_ids), id)
  ]

  assigned_definition_roles = merge(
    {
      for id, d in data.azapi_resource.assigned_definition :
      id => coalesce(try(tolist(d.output.roles), null), [])
    },
    {
      for key, definition in local.policy_definitions :
      local.policy_definition_ids[key] => coalesce(
        try(tolist(definition.properties.policyRule.then.details.roleDefinitionIds), null),
        []
      )
    }
  )

  assigned_definition_members = merge(
    {
      for id, d in data.azapi_resource.assigned_definition :
      id => coalesce(try(tolist(d.output.members), null), [])
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
      id => coalesce(try(tolist(d.output.roles), null), [])
    },
    {
      for key, definition in local.policy_definitions :
      local.policy_definition_ids[key] => coalesce(
        try(tolist(definition.properties.policyRule.then.details.roleDefinitionIds), null),
        []
      )
    }
  )

  # Roles required by the definition itself, or by all members for an initiative.
  definition_role_guids = {
    for id in local.assigned_definition_ids : id => distinct([
      for r in concat(
        coalesce(try(local.assigned_definition_roles[id], null), []),
        flatten([
          for member_id in coalesce(try(local.assigned_definition_members[id], null), []) :
          coalesce(try(local.member_definition_roles[member_id], null), [])
        ])
      ) : lower(regex("[^/]+$", r))
    ])
  }

  # One role assignment per role required by the assigned definition, at the scope of the assignment.
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