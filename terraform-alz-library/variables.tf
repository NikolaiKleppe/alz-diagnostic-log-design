variable "location" {
  description = "Azure region for the policy assignment managed identities and the Defender for Cloud export resource group."
  type        = string
  default     = "northeurope"
}

variable "architecture_name" {
  description = "Name of the architecture definition in lib/architecture_definitions."
  type        = string
  default     = "alz_security"
}

variable "root_management_group_name" {
  description = "Name of the root of the ALZ hierarchy (the id of the management group with parent_id null in the architecture)."
  type        = string
  default     = "alz"
}

variable "platform_management_group_name" {
  description = "Name of the Platform management group (must match lib/architecture_definitions)."
  type        = string
  default     = "platform"
}

variable "landing_zones_management_group_name" {
  description = "Name of the Landing Zones management group (must match lib/architecture_definitions)."
  type        = string
  default     = "landingzones"
}

variable "security_workspace_id" {
  description = "Resource ID of the security Log Analytics workspace (Sentinel enabled) in the Security subscription."
  type        = string
}

variable "security_contact_email" {
  description = "Email address for the Defender for Cloud security contact."
  type        = string
}

variable "mdfc_export_resource_group_name" {
  description = "Resource group name used by the Defender for Cloud continuous export."
  type        = string
  default     = "rg-mdfc-export-prod"
}
