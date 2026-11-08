variable "default_location" {
  description = "Azure region for the policy assignment managed identities. Replaces $${default_location} in the assignment files."
  type        = string
  default     = "northeurope"
}

variable "root_management_group_id" {
  description = "ID (name) of the intermediate root management group of the ALZ hierarchy. The ALZ definitions are deployed here by the platform repository."
  type        = string
  default     = "alz"
}

variable "platform_management_group_id" {
  description = "ID (name) of the Platform management group."
  type        = string
  default     = "platform"
}

variable "landing_zones_management_group_id" {
  description = "ID (name) of the Landing Zones management group."
  type        = string
  default     = "landingzones"
}

variable "security_workspace_id" {
  description = "Resource ID of the security Log Analytics workspace (Sentinel enabled) in the Security subscription."
  type        = string
}

variable "security_contact_email" {
  description = "Email address for the Defender for Cloud security contact (Sec-MDFC-Config)."
  type        = string
}

variable "mdfc_export_resource_group_name" {
  description = "Resource group name used by the Defender for Cloud continuous export (Sec-MDFC-Config)."
  type        = string
  default     = "rg-mdfc-export-prod"
}
