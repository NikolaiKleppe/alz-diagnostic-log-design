# Terraform approach comparison: plain `azapi` or ALZ library

Two proofs of concept for the security repository's policy assignments were built and planned against live Azure:

- **[terraform/](./terraform) (plain `azapi`):** one JSON file per assignment, read with `fileset()` and deployed with `azapi_resource` in a `for_each`. Required roles are derived from the policy definitions.
- **[terraform-alz-library/](./terraform-alz-library):** a custom ALZ library that depends on `platform/alz` (pinned at `2026.11.0`), with standalone archetypes and an architecture with `exists: true` management groups. It is consumed through the ALZ provider and the `Azure/avm-ptn-alz/azurerm` module. The plan succeeded with 33 resources (5 assignments, 2 definitions, 20 role assignments and 6 helper resources).

## Recommendation

**Use the plain `azapi` approach** for about five assignments. Consuming the ALZ library adds little at this size.

## What the library gave

| Area | Finding |
|------|---------|
| Upstream reuse | Four of the five assignments reference built-in definitions, which exist in Azure regardless of the library. The library only supplied the assignment JSON wrapper and the parameter defaults |
| Role assignments | The provider derives them automatically. The plain `azapi` approach does the same in about 30 lines (`locals.tf`, `main.tf`), and the plan gave the same roles (20 role assignments across the five assignments) |
| Version pinning | The library approach pins through the library dependency. The plain approach has self-contained JSON, and built-in definitions are pinned with `definitionVersion` (`1.*.*`). Nothing changes unless the security team edits a file, which reduces R-02 and R-10 |

## What the library cost

- More moving parts: the ALZ provider, the AVM module, a GitHub download at plan time (`.alzlib/`) and a custom library layout.
- **The A15 limitation applies anyway.** `Deploy-MDFC-Config-H224` references the ALZ-defined initiative `Deploy-MDFC-Config_20240319`. It is not deployed in a security-only hierarchy, so the provider left `managementGroups/placeholder` in the definition ID and an apply would have failed. A renamed security-owned copy was needed (DD08), the same maintenance burden as without the library.
- Upstream churn without a matching benefit, for example the April 2026 library changes (ADV01).

## When the library would pay off

- The security repository grows to dozens of assignments across many management groups.
- The provider should compute scopes, defaults and hierarchy exactly the way the platform repository does.

## Caveats of the plain `azapi` approach

| Caveat | Handling |
|--------|----------|
| `Sec-MDFC-Config` references the ALZ-defined initiative `Deploy-MDFC-Config_20240319` at the root scope, which is deployed by the platform repository (R-10). The library PoC showed this does not resolve without a definition in the hierarchy | To follow DD08, deploy a renamed security-owned copy of the initiative and its member definition `Deploy-ASC-SecurityContacts` from the `terraform/` repository (not yet implemented there). The library PoC contains the renamed copies in `terraform-alz-library/lib/policy_set_definitions` and `terraform-alz-library/lib/policy_definitions` |
| Upstream tracking is lost. The upgrade step "review new, removed and changed assignments" is manual | Record the library tag in each JSON file and add a CI job that diffs the files against the pinned library tag |
| Management group ids are variables, not read from an architecture file | Keep the variables aligned with the platform repository, and verify in the routing inventory check |

## Design impact

Applied in section 4.3 of the [design](./design/alz-diagnostic-logging-design.md): the new subsection "Library use by the security repository" and decision **DD09**, with DD06, DD04, A02, section 3.4 and the L2 diagram reworded. The security repository uses the library only as a reference for assignment content, with a recorded library version and a CI comparison, and not as a tool or a dependency.

## Status of the two folders

| Folder | Status |
|--------|--------|
| [terraform/](./terraform) | Selected approach (DD09) |
| [terraform-alz-library/](./terraform-alz-library) | Kept as a documented alternative. It is not deployed and is revisited when the number of assignments or management groups grows substantially (see the section on when the library would pay off) |

## Open follow-ups

- Add the DD08 definition deployment (renamed initiative and member definition) to the plain `azapi` approach.
- Add the CI comparison against the recorded library version, and record that version in each assignment file (DD06).
