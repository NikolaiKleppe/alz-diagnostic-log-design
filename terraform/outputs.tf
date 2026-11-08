output "policy_assignment_ids" {
  description = "Resource IDs of the security policy assignments, keyed by file name."
  value       = { for k, v in azapi_resource.policy_assignment : k => v.id }
}

output "role_assignment_ids" {
  description = "Resource IDs of the role assignments for the policy assignment identities."
  value       = { for k, v in azapi_resource.role_assignment : k => v.id }
}

output "policy_definition_ids" {
  description = "Resource IDs of the security-owned policy definitions, keyed by file name."
  value       = { for k, v in azapi_resource.policy_definition : k => v.id }
}

output "policy_set_definition_ids" {
  description = "Resource IDs of the security-owned policy set definitions, keyed by file name."
  value       = { for k, v in azapi_resource.policy_set_definition : k => v.id }
}
