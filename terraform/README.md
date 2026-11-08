# Security policy assignments (proof of concept)

Selected approach (design decision DD09). The alternative that uses the ALZ provider and module is documented in [../terraform-alz-library/](../terraform-alz-library), and the comparison is in [../terraform-approach-comparison.md](../terraform-approach-comparison.md).

Terraform for the policy definitions and assignments owned by the **security repository** in the design ([alz-diagnostic-logging-design.md](../design/alz-diagnostic-logging-design.md)). It follows the ALZ Library pattern: one JSON file per definition, initiative, and assignment in their corresponding folders.

## Structure

| File | Purpose |
|------|---------|
| `policy_assignments/*.alz_policy_assignment.json` | One file per assignment, same format as the ALZ Library |
| `policy_definitions/*.alz_policy_definition.json` | One file per custom policy definition |
| `policy_set_definitions/*.alz_policy_set_definition.json` | One file per custom initiative |
| `locals.tf` | Shared template variables |
| `locals.policy_assignments.tf` | Reads assignments, resolves definition IDs and derives required roles |
| `locals.policy_definitions.tf` | Reads custom policy definitions |
| `locals.policy_set_definitions.tf` | Reads custom policy set definitions |
| `main.policy_assignments.tf` | `azapi_resource` for each assignment, plus definition reads and required role assignments |
| `main.policy_definitions.tf` | `azapi_resource` for each custom policy definition |
| `main.policy_set_definitions.tf` | `azapi_resource` for each custom initiative |
| `variables.tf` | Management groups, security workspace and shared Defender for SQL inputs |

## Add or remove a policy

- **Add:** create a `<name>.alz_policy_definition.json`, `<name>.alz_policy_set_definition.json`, or `<name>.alz_policy_assignment.json` in the corresponding folder. The file name is Terraform's key; the JSON `name` is the Azure resource name and may differ from the file name. Assignment resource names must be at most 24 characters.
- **Remove:** delete the file. Terraform destroys dependent assignments and initiatives before their definitions.

No Terraform change is needed in either case.

## Tokens

The JSON files can use these tokens, which are replaced before the file is decoded: `${default_location}`, `${root_scope}`, `${platform_scope}`, `${landing_zones_scope}`, `${security_workspace_id}`, `${security_contact_email}`, `${mdfc_export_resource_group_name}`. To add a token, add it to `template_vars` in `locals.tf`.

## Role assignments

The assignment files carry no role information, as in the ALZ Library. Terraform reads the assigned definition (and the member definitions of an initiative) and creates a role assignment at the assignment scope for each role in `roleDefinitionIds`. This follows what the ALZ provider does and avoids hardcoded roles drifting from the pinned definitions.

Built-in definitions are read during plan. Custom definitions and initiatives are loaded from their JSON files and deployed at the root management group; ALZ `placeholder` references resolve to the configured root management group. The security-owned `Sec-Deploy-MDFC-Config_20240319` initiative includes the security-owned `Sec-Deploy-ASC-SecurityContacts` definition (DD08, A15).

## Custom definitions

| JSON file | Definition name | Purpose |
|-----------|-----------------|---------|
| `policy_definitions/Deploy-ASC-SecurityContacts.alz_policy_definition.json` | `Deploy-ASC-SecurityContacts` | Security-owned copy of the ALZ Library security contacts policy (DD08) |
| `policy_set_definitions/Deploy-MDFC-Config_20240319.alz_policy_set_definition.json` | `Sec-Deploy-MDFC-Config_20240319` | Security-owned copy of the Defender for Cloud configuration initiative (DD08) |

## Assignments

| JSON file | Assignment name | Definition | Scope | Design |
|-----------|-----------------|------------|-------|--------|
| `Deploy-Diag-LogsCat.alz_policy_assignment.json` | `Sec-Diag-AllLogs` | Built-in `allLogs` initiative, curated `resourceTypeList` | Root | SEC02 |
| `Deploy-AzSqlDb-Auditing.alz_policy_assignment.json` | `Sec-AzSqlDb-Auditing` | Built-in SQL auditing policy | Root | SEC05 |
| `Deploy-AzActivity-Log.alz_policy_assignment.json` | `Sec-AzActivity-Log` | Built-in Activity Log diagnostic settings policy | Root | MON02 |
| `Deploy-MDFC-Config-H224.alz_policy_assignment.json` | `Sec-MDFC-Config` | Security-owned `Sec-Deploy-MDFC-Config_20240319` initiative | Root | SEC04 |
| `Deploy-MDFC-DefSQL-AMA.alz_policy_assignment.json` | `Sec-MDFC-DefSQL-AMA` | Built-in Defender for SQL initiative | Root | SEC04 |

- The `resourceTypeList` in `Sec-Diag-AllLogs` (Key Vault, Azure Firewall, Container Registry) is an example. The real list depends on OQ04 and A08.
- The filenames retain the corresponding ALZ Library assignment names; the JSON `name` fields use `Sec-*` names for the security-owned assignments. The platform repository must disable the library assignments `Deploy-AzSqlDb-Auditing`, `Deploy-MDFC-Config-H224` and `Deploy-MDFC-DefSQL-AMA` before this repository takes over those policies.
- All five assignments currently target the root management group. The Activity Log second route (MON02) is included; Entra ID tenant logs (SEC06) are not part of this PoC.
- The root scope is an assumption (A13); confirm whether each assignment should target that management group.
- The policy identities need write access to the security workspace (A12). The role assignments are created at the assignment scope only, so the workspace may need an additional role assignment.

## Usage

```powershell
terraform init
terraform plan -var-file="env/dev.tfvars"
```

Edit the selected environment file first; `env/dev.tfvars` and `env/prod.tfvars` are provided.
Authentication uses the standard `azapi` provider mechanisms (for example `az login` and `ARM_SUBSCRIPTION_ID`).
