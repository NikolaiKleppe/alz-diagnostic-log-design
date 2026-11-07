# Security policy assignments with the ALZ provider (proof of concept)

> **Status: documented alternative, not selected.** The security repository uses the plain `azapi` approach in [../terraform/](../terraform) (design decision DD09). This folder is kept to document the library-based option and its findings. See [../terraform-approach-comparison.md](../terraform-approach-comparison.md) for the comparison and when to revisit it.

Alternative to [../terraform/](../terraform): the security repository is a small **custom ALZ library** that depends on the upstream `platform/alz` library, consumed through the ALZ provider and the `Azure/avm-ptn-alz/azurerm` module. Role assignments, scope resolution and parameter defaults are handled by the provider and module.

## Structure

```text
lib/
  alz_library_metadata.json                  dependency on platform/alz 2026.11.0 (DD06)
  architecture_definitions/
    alz_security.*.yaml                      management groups with exists: true, so only assignments are deployed
  archetype_definitions/
    security_root.*.yaml                     Sec-Diag-AllLogs, Sec-MDFC-Config (+ renamed definitions)
    security_platform.*.yaml                 Deploy-MDFC-DefSQL-AMA
    security_landing_zones.*.yaml            Deploy-AzSqlDb-Auditing, Deploy-MDFC-DefSQL-AMA
  policy_assignments/                        custom assignments (Sec-*)
  policy_definitions/                        security-owned copy of an ALZ definition (DD08)
  policy_set_definitions/                    security-owned copy of an ALZ initiative (DD08)
versions.tf, variables.tf, main.tf           provider, inputs and the module call
```

## How a policy is added or removed

| Case | Change |
|------|--------|
| Assign an existing library assignment | Add its name to an archetype `policy_assignments` list. Set workspace values through `policy_default_values` or `policy_assignments_to_modify` in `main.tf` |
| Assign a new policy | Add `<name>.alz_policy_assignment.json` to `lib/policy_assignments/` and list it in an archetype |
| Remove | Remove the name from the archetype (and delete the file for a custom assignment) |

No assignment is declared in Terraform. The module creates one resource per assignment and one per required role assignment.

## Assignments

| Assignment | Source | Archetype / scope | Design |
|------------|--------|-------------------|--------|
| `Sec-Diag-AllLogs` | Custom, built-in `allLogs` initiative with curated `resourceTypeList` | `security_root` | SEC02 |
| `Sec-MDFC-Config` | Custom, security-owned copy of the ALZ initiative | `security_root` | SEC04, DD08 |
| `Deploy-MDFC-DefSQL-AMA` | Library assignment by name | `security_platform`, `security_landing_zones` | SEC04 |
| `Deploy-AzSqlDb-Auditing` | Library assignment by name | `security_landing_zones` | SEC05 |

## Findings from the PoC plan

- **Built-in definitions need no extra work.** Library assignments that reference built-in definitions resolve without the platform deployment, and the library defaults (`log_analytics_workspace_id`, `ama_*`) are applied to them.
- **ALZ-defined definitions do not resolve (verification item A15).** `Deploy-MDFC-Config-H224` references the ALZ-defined initiative `Deploy-MDFC-Config_20240319`. This hierarchy does not deploy it, so the provider leaves `managementGroups/placeholder` in the definition ID, and an apply would fail. This is why `Sec-MDFC-Config` and the renamed definitions are part of the library (DD08). The copies are byte-for-byte upstream (platform/alz 2026.11.0) apart from the name, the member reference and a `securityCopyOf` metadata note. Compare them with upstream on every library upgrade (DD05).
- **Roles are derived by the provider.** The plan contains 20 policy role assignments (alz 8, platform 5, landingzones 7), matching the roles of the referenced definitions.
- **Library assignments that are taken over keep their upstream names.** The platform repository must disable `Deploy-AzSqlDb-Auditing` and `Deploy-MDFC-DefSQL-AMA` before this repository assigns them (DD07). The `Sec-` prefixed assignments cannot collide with library names.

## Assumptions

- The management groups exist with the ids in `lib/architecture_definitions` (`alz`, `platform`, `landingzones`). The parent of the architecture root is the tenant root group.
- The resource types in `Sec-Diag-AllLogs` (Key Vault, Azure Firewall, Container Registry) are examples (OQ04, A08).
- Policy identities need write access to the security workspace (A12). The role assignments are created at the assignment scope only.
- The Activity Log second route (MON02) and Entra ID tenant logs (SEC06) are not part of this PoC.

## Usage

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars   # then edit the values
terraform init
terraform plan
```

The ALZ provider downloads `platform/alz` into `.alzlib/` (ignored by git). It needs access to GitHub and to Azure (for example `az login` and `ARM_SUBSCRIPTION_ID`), because built-in definitions are read from Azure.
