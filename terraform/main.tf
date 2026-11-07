# The ALZ provider derives role assignments from the policy definitions. Without it, the same is done here.
data "azapi_resource" "assigned_definition" {
  for_each = toset(local.assigned_definition_ids)

  type        = strcontains(lower(each.key), "/policysetdefinitions/") ? "Microsoft.Authorization/policySetDefinitions@2023-04-01" : "Microsoft.Authorization/policyDefinitions@2023-04-01"
  resource_id = each.key

  response_export_values = {
    roles   = "properties.policyRule.then.details.roleDefinitionIds"
    members = "properties.policyDefinitions[].policyDefinitionId"
  }
}

data "azapi_resource" "member_definition" {
  for_each = toset(local.member_definition_ids)

  type        = "Microsoft.Authorization/policyDefinitions@2023-04-01"
  resource_id = each.key

  response_export_values = {
    roles = "properties.policyRule.then.details.roleDefinitionIds"
  }
}

resource "azapi_resource" "policy_assignment" {
  for_each = local.policy_assignments

  type      = "${each.value.type}@${each.value.apiVersion}"
  name      = each.value.name
  parent_id = each.value.properties.scope
  location  = each.value.location

  body = {
    properties = { for k, v in each.value.properties : k => v if k != "scope" }
  }

  dynamic "identity" {
    for_each = try(each.value.identity, null) != null ? [each.value.identity] : []
    content {
      type = identity.value.type
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.name == each.key
      error_message = "The name in ${each.key}${local.policy_assignment_suffix} (${each.value.name}) must match the file name."
    }
    precondition {
      condition     = length(each.value.name) <= 24
      error_message = "Policy assignment names at management group scope are limited to 24 characters (${each.value.name})."
    }
  }
}

resource "azapi_resource" "role_assignment" {
  for_each = local.role_assignments

  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("url", "${each.value.scope}/${each.key}")
  parent_id = each.value.scope

  body = {
    properties = {
      roleDefinitionId = each.value.role_definition_id
      principalId      = azapi_resource.policy_assignment[each.value.assignment_key].identity[0].principal_id
      principalType    = "ServicePrincipal"
    }
  }

  # The managed identity can take a while to replicate in Microsoft Entra ID
  retry = {
    error_message_regex = ["PrincipalNotFound"]
  }
}
