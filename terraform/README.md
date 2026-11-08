# Security policy assignments (proof of concept)

Selected approach (design decision DD09). The alternative that uses the ALZ provider and module is documented in [../terraform-alz-library/](../terraform-alz-library), and the comparison is in [../terraform-approach-comparison.md](../terraform-approach-comparison.md).

Terraform for the policy definitions and assignments owned by the **security repository** in the design ([alz-diagnostic-logging-design.md](../design/alz-diagnostic-logging-design.md)). It follows the ALZ Library pattern: one JSON file per definition, initiative, and assignment in their corresponding folders.

## Structure

| File | Purpose |
|------|---------|
| `policy_assignments/*.alz_policy_assignment.json` | One file per assignment, same format as the ALZ Library |
| `policy_definitions/*.alz_policy_definition.json` | One file per custom policy definition |
| `policy_set_definitions/*.alz_policy_set_definition.json` | One file per custom initiative |
| `locals.tf` | Reads and decodes every JSON file, resolves tokens, derives the required roles |
| `main.policy_assignments.tf` | `azapi_resource` for each assignment, plus definition reads and required role assignments |
| `main.policy_definitions.tf` | `azapi_resource` for each custom policy definition |
| `main.policy_set_definitions.tf` | `azapi_resource` for each custom initiative |
| `variables.tf` | Management groups, security workspace and shared Defender for SQL inputs |

## Add or remove a policy

- **Add:** create a matching `<name>.alz_policy_definition.json`, `<name>.alz_policy_set_definition.json`, or `<name>.alz_policy_assignment.json` in the corresponding folder. The JSON `name` must match the file name; assignment names must be at most 24 characters.
- **Remove:** delete the file. Terraform destroys dependent assignments and initiatives before their definitions.

No Terraform change is needed in either case.

## Tokens

The JSON files can use these tokens, which are replaced before the file is decoded: `${default_location}`, `${root_scope}`, `${platform_scope}`, `${landing_zones_scope}`, `${security_workspace_id}`, `${security_contact_email}`, `${mdfc_export_resource_group_name}`. To add a token, add it to `template_vars` in `locals.tf`.

## Role assignments

The assignment files carry no role information, as in the ALZ Library. Terraform reads the assigned definition (and the member definitions of an initiative) and creates a role assignment at the assignment scope for each role in `roleDefinitionIds`. This follows what the ALZ provider does and avoids hardcoded roles drifting from the pinned definitions.

Built-in definitions are read during plan. Custom definitions and initiatives are loaded from their JSON files and deployed at the root management group; ALZ `placeholder` references resolve to the configured root management group. The security-owned `Sec-Deploy-MDFC-Config_20240319` initiative includes the security-owned `Sec-Deploy-ASC-SecurityContacts` definition (DD08, A15).

## Assignments

| File | Definition | Scope | Design |
|------|------------|-------|--------|
| `Sec-Diag-AllLogs` | Built-in `allLogs` initiative, curated `resourceTypeList` | Root | SEC02 |
| `Sec-AzSqlDb-Auditing` | Built-in SQL auditing | Landing Zones | SEC05 |
| `Sec-MDFC-Config` | Security-owned `Sec-Deploy-MDFC-Config_20240319` initiative | Root | SEC04 |
| `Deploy-DefSQL-AMA-Plat` | Built-in Defender for SQL initiative | Platform | SEC04 |
| `Deploy-DefSQL-AMA-LZ` | Built-in Defender for SQL initiative | Landing Zones | SEC04 |

- The `resourceTypeList` in `Sec-Diag-AllLogs` (Key Vault, Azure Firewall, Container Registry) is an example. The real list depends on OQ04 and A08.
- The `Deploy-` prefix follows the ALZ Library naming convention. Scope suffixes keep the Defender for SQL assignment names unique. The platform repository must disable the library assignments `Deploy-AzSqlDb-Auditing`, `Deploy-MDFC-Config-H224` and `Deploy-MDFC-DefSQL-AMA` first.
- The Activity Log second route (MON02) and Entra ID tenant logs (SEC06) are not part of this PoC.
- Scopes are an assumption (A13): confirm where each assignment sits in the management group hierarchy.
- The policy identities need write access to the security workspace (A12). The role assignments are created at the assignment scope only, so the workspace may need an additional role assignment.

## Usage

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars   # then edit the values
terraform init
terraform plan
```

Authentication uses the standard `azapi` provider mechanisms (for example `az login` and `ARM_SUBSCRIPTION_ID`).
