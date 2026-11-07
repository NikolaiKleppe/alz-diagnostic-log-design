output "policy_assignment_ids" {
  description = "Resource IDs of the security policy assignments, keyed by file name."
  value       = { for k, v in azapi_resource.policy_assignment : k => v.id }
}

output "role_assignment_ids" {
  description = "Resource IDs of the role assignments for the policy assignment identities."
  value       = { for k, v in azapi_resource.role_assignment : k => v.id }
}
