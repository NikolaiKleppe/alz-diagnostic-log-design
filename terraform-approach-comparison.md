# Terraform approach comparison: plain `azapi` or ALZ library

Two approaches for the security repository's policy assignments were prototyped and planned against live Azure. The selected plain `azapi` approach has since been extended to deploy the security-owned definitions required by DD08:

- **[terraform/](./terraform) (plain `azapi`):** JSON files for assignments, custom policy definitions and custom initiatives are read with `fileset()` and deployed with `azapi_resource` in `for_each` resources. Required roles are derived from built-in, external and local policy definitions, including initiative members.
- **[terraform-alz-library/](./terraform-alz-library):** a custom ALZ library that depends on `platform/alz` (pinned at `2026.11.0`), with standalone archetypes and an architecture with `exists: true` management groups. It is consumed through the ALZ provider and the `Azure/avm-ptn-alz/azurerm` module. The plan succeeded with 33 resources (5 assignments, 2 definitions, 20 role assignments and 6 helper resources).

## Recommendation

**Use the plain `azapi` approach** for about five assignments. Consuming the ALZ library adds little at this size.

## What the library gave

| Area | Finding |
|------|---------|
| Upstream reuse | Four of the five assignments reference built-in definitions, which exist in Azure regardless of the library. `Sec-MDFC-Config` needs the DD08 security-owned copies in either approach; the library approach packages those copies in its custom library. The library also supplies assignment defaults and provider/module-driven scope and role handling |
| Role assignments | The provider derives them automatically. The plain `azapi` implementation derives roles from external and local definitions (including initiative members) and creates role assignments at each policy assignment's scope. The PoC plan showed the same 20 roles across the five assignments |
| Version pinning | The library approach pins through the library dependency. The plain approach has self-contained JSON; built-in definitions use Azure Policy `definitionVersion` (`1.*.*`), and the DD08 copies identify their ALZ Library source version in metadata. However, the assignment files do not yet record their library version and there is no CI comparison. The approach avoids an ALZ Library runtime dependency but does not yet provide automated upstream change tracking |

## What the `azapi` approach gave

- **Direct resource control.** The security repository deploys its assignments, custom policy definition and initiative from local JSON files without an ALZ provider, AVM module or downloaded library at plan time.
- **A solution to the placeholder scope issue.** The security-owned DD08 definition and initiative are deployed at the root management group, with placeholder references rewritten to that scope.
- **Derived role assignments.** Terraform reads roles from external and local policy definitions, including initiative members, and creates the required role assignments.
- **Small, explicit configuration.** `fileset()` loads the JSON files, so assignments and custom definitions can be added or removed without changing Terraform resource blocks.

## What the library cost

- More moving parts: the ALZ provider, the AVM module, a GitHub download at plan time (`.alzlib/`) and a custom library layout.
- **The A15 limitation requires a security-owned copy in either approach.** The library PoC left `managementGroups/placeholder` in the ALZ-defined initiative reference because that initiative is not deployed in the security-only hierarchy. DD08 addresses this with renamed security-owned copies; the selected plain `azapi` implementation now deploys `Sec-Deploy-ASC-SecurityContacts` and `Sec-Deploy-MDFC-Config_20240319` at the root management group and rewrites placeholder references to that scope.
- Upstream churn without a matching benefit, for example the April 2026 library changes (ADV01).

## When the library would pay off

- The security repository grows to dozens of assignments across many management groups.
- The provider should compute scopes, defaults and hierarchy exactly the way the platform repository does.

## Caveats of the plain `azapi` approach

| Caveat | Handling |
|--------|----------|
| Upstream tracking is manual. Assignment files do not record the ALZ Library version, and no CI comparison is implemented | Record the source library version in each assignment file and add a CI job that reports added, removed and changed assignments against that version |
| Management group ids are variables, not read from an architecture file | Keep the variables aligned with the platform repository, and verify in the routing inventory check |

## Design impact

Applied in section 4.3 of the [design](./design/alz-diagnostic-logging-design.md): the new subsection "Library use by the security repository" and decision **DD09**, with DD06, DD04, A02, section 3.4 and the L2 diagram reworded. The security repository uses the library only as a reference for assignment content, with a recorded library version and a CI comparison, and not as a tool or a dependency.

## Status of the two folders

| Folder | Status |
|--------|--------|
| [terraform/](./terraform) | Selected approach (DD09) |
| [terraform-alz-library/](./terraform-alz-library) | Kept as a documented alternative. It is not deployed and is revisited when the number of assignments or management groups grows substantially (see the section on when the library would pay off) |

## Open follow-ups

- Record the ALZ Library source version in each assignment file and add a CI comparison against that version (DD06).
