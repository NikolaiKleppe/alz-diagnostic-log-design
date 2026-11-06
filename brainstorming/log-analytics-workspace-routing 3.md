# ALZ Log Analytics Workspace Routing

## Context

The ALZ library defines a shared default named `log_analytics_workspace_id`. The ALZ Terraform module passes that value to the ALZ provider, which applies it to the matching parameters on the listed policy assignments. The value is a Log Analytics workspace **ARM resource ID**, supplied as a JSON-encoded parameter value.

The current ALZ library mapping includes:

| Policy assignment | Parameter | Purpose |
| --- | --- | --- |
| `Deploy-AzActivity-Log` | `logAnalytics` | Route subscription Activity Logs |
| `Deploy-AzSqlDb-Auditing` | `logAnalyticsWorkspaceId` | Route SQL auditing |
| `Deploy-Diag-LogsCat` | `logAnalytics` | Route supported resource diagnostic logs |
| `Deploy-MDFC-Config-H224` | `logAnalytics` | Configure Defender for Cloud continuous export |
| `Deploy-MDFC-DefSQL-AMA` | `userWorkspaceResourceId` | Configure the workspace for Defender for SQL AMA collection |

This is a shared default, not automatic discovery of a workspace. If no value is provided, the library's placeholder values are not usable deployment destinations; supply real workspace IDs for the assignments you enable.

## Two-workspace requirement

The intended design has:

- a **management workspace** (in the `alz-management` management group) for operational/ALZ logs;
- a **security workspace** for security monitoring, including Defender for Cloud logs; and
- Activity Logs in **both** workspaces.

The shared default gives each mapped parameter one value; it does not send a log stream to two workspaces. To collect a stream in both, configure a second destination as well, for example a second policy assignment or diagnostic-setting route, where supported.

For `Deploy-Diag-LogsCat`, this means keeping one assignment pointed at one workspace and adding a distinct assignment/route for the other. A duplicate assignment is not populated by the shared default unless it is explicitly mapped/configured in the ALZ library or overridden in Terraform. Verify the duplicate assignment's name, scope, policy identity permissions, and resulting diagnostic-setting behavior as part of implementation.

## Upstream status: the ALZ security management group and subscription

ALZ has introduced a dedicated Security management group (beneath Platform) and a security subscription. This does not change the routing policies:

- **The security subscription is intentionally empty.** Per the proposal (Azure/Enterprise-Scale discussion #1978), ALZ deploys nothing into it: no security workspace and no Sentinel. It is created outside ALZ (subscription vending or manually) and moved into the management group. The reasons given were to avoid starting the Sentinel free trial early and to avoid interfering with customers who already have their own Sentinel deployment.
- **Sentinel is not deployed by default.** The ALZ "What's new" page states that the portal accelerator no longer deploys Sentinel or offers it as an option, and that guidance for manual deployment is provided. In the AVM Terraform module, Sentinel is enabled through the `sentinel_onboarding` input and is not on by default.
- **No upstream routing decision exists.** Discussions #1898 and #1978 reached a general consensus that a separate security workspace is needed (cost, access control, blast radius, separation of operational and security logs). Neither defines how Activity Logs, diagnostic settings, Defender for Cloud export or SQL auditing should route between a management and a security workspace.
- **The library still has one shared workspace default.** `alz_policy_default_values.json` maps `log_analytics_workspace_id` to the same five assignments listed above, with no Sentinel-specific default.

Consequences for this decision:

- The Security management group is a place to host your own security workspace, not a routing model. Routing to it remains your own configuration.
- There is no upstream support for "a security MG implies security-first routing", and none for the opposite either. The default-destination choice is a local governance decision.
- Revisit this section on library upgrades, since upstream may define routing for the security workspace later.

Items to verify against the library version you pin:

- The April 2026 "What's new" entry says several diagnostic and flow-log policies were removed as superseded by built-ins, including the `Deploy-Diagnostics-LogAnalytics` initiative. It does not name `Deploy-Diag-LogsCat`, nor say whether built-in replacements take the same parameters. Confirm that `Deploy-Diag-LogsCat` and its `logAnalytics` parameter still exist.
- Check which management group the library's architecture definition assigns each workspace-dependent policy to, especially `Deploy-MDFC-DefSQL-AMA`, and whether the Security management group has any archetype or assignments of its own.
- The ALZ policy assignments documentation page may lag the library and does not mention the Security management group. Treat the library repository as the source of truth.

## Decided approach (November 2026)

- **Two workspaces:** one for ALZ/platform operations (management) and one for security logs.
- **Sentinel** is enabled on the security workspace.
- **Separate repositories:** the security team manages its diagnostic settings policies in its own repo, with its own policy assignments, and decides which logs go to the security workspace.
- **Activity Logs** are ingested in both workspaces. The extra ingestion cost is accepted.
- **Tenant-level logs** (such as Entra ID) are owned by security and defined in Terraform in the security repo.
- **Defender for Cloud assignments** are leaning toward being handed over to security, since those logs are not needed in the operations workspace. Not final.
- **Microsoft guidance:** this matches the exception in the CAF single-workspace recommendation (RBAC and data ownership). A Microsoft solution architect (Customer Success) recommended separate workspaces and separate repositories with separate policy assignments.

### Why a separate workspace is justified

- CAF recommends a single central workspace by default, except where RBAC, data sovereignty or retention require separate workspaces. Security ownership of Sentinel and its data is such a case.
- When Sentinel is enabled on a workspace, all data in it is billed at Sentinel rates, including operational data. Operational data therefore stays out of the security workspace unless security needs it.
- Microsoft's sample Sentinel workspace designs separate SOC and operations workspaces and route sources per workspace with diagnostic settings.
- Microsoft advises keeping Sentinel and Defender for Cloud data in the same workspace.

### Ownership boundary

| Area | Owner | Notes |
| --- | --- | --- |
| Management default (`log_analytics_workspace_id`), library assignments, `Deploy-AzActivity-Log` and `Deploy-Diag-LogsCat` to management | ALZ repo | Management workspace |
| Duplicate `Deploy-Diag-LogsCat`, second Activity Log route, other diagnostic policies for the security workspace | Security repo | Security chooses the log categories |
| Tenant-level logs (Entra ID and similar) | Security repo | Defined in Terraform; needs the appropriate Entra and provider permissions |
| `Deploy-MDFC-Config-H224`, `Deploy-MDFC-DefSQL-AMA` | Leaning toward Security repo | See the handover notes below |
| `Deploy-AzSqlDb-Auditing` | To be decided | Security if SQL auditing is a security-owned signal |

Rule: no policy is assigned from both repos.

### If the Defender assignments are handed over to security

- **It is more than log routing.** `Deploy-MDFC-Config-H224` also takes parameters for the security contact email, the export resource group name and location, so security would own the whole assignment, not only the export destination.
- **Disable them in the ALZ repo first.** The ALZ library deploys both assignments by default. Remove or disable them there (for example with `DoNotEnforce`, or by tailoring the archetype) before security assigns its own, so the same policy is not assigned twice. Check the mechanism in your module version.
- **Shared inputs.** `Deploy-MDFC-DefSQL-AMA` also uses the AMA managed identity and the Defender for SQL data collection rule defaults, which come from the platform side. Agree how security receives those values.
- **Pin and track.** Security's copies no longer follow library updates, so security must pin policy definition versions and review upstream changes.

### Open questions

- Sentinel cost options (Auxiliary Logs, ingestion-time transformations, the data lake) for high-volume platform diagnostics. To be clarified with Microsoft later.
- Final decision on handing the Defender for Cloud assignments to security.

## Decision

**Keep the management workspace as the shared ALZ default, and explicitly route security-specific policies to the security workspace.** Add a second route for any data both teams need, such as Activity Logs.

This follows the intended ALZ baseline, keeps the security-specific split visible in code, and needs only a handful of explicit definitions, written once.

## Default-destination choice

### Option A: Management workspace as the shared ALZ default (chosen)

Use the management workspace for `log_analytics_workspace_id`, then explicitly route security-specific policies to the security workspace and duplicate selected routes that must reach both.

**Advantages**

- Keeps the common ALZ destination aligned with general management and operations.
- Makes the security-specific split visible in configuration.
- Limits accidental routing of non-security logs to the security workspace.
- Matches the intended ALZ architecture, so library updates and upstream documentation apply without translation.

**Tradeoff**

- When the ALZ library adds a workspace-dependent assignment, it may inherit the management workspace until the configuration is reviewed and changed. This is mitigated by the review process described below.

### Option B: Security workspace as the shared default

Use the security workspace for `log_analytics_workspace_id`, then explicitly duplicate or override assignments that also need to send data to management.

**Advantages**

- A newly mapped workspace-dependent policy is more likely to land in the security team's workspace by default.
- Supports a deliberate organizational rule that security receives all applicable logs unless a policy is explicitly routed elsewhere.

**Tradeoffs**

- The shared default is not limited to Defender policies: it also covers Activity Logs, SQL auditing, and broad resource diagnostics.
- It may route operational data to security when that was not intended, and can increase ingestion/retention costs.
- It still does not create a second copy in management; that destination must be configured explicitly.

## Assessing the "safety net" argument for Option B

The main argument for Option B is that a new or missed workspace-dependent assignment would then land with security instead of being silently missed. This is weaker than it sounds:

- **The failure mode is symmetric.** The default only changes which workspace a missed assignment lands in. A new assignment inheriting the management default is not worse than one inheriting the security default; either needs review.
- **The default does not create the second copy.** Every assignment that must reach management still has to be duplicated or overridden explicitly, so Option B gives no protection against forgetting those.
- **The default is broad, not security-specific.** It covers Activity Logs, SQL auditing and broad resource diagnostics, so Option B moves a large volume of operational data into the security workspace, with the ingestion and retention costs and ownership questions that come with it.
- **The real safeguard is process, not the default value.** A reviewed routing list and a library-upgrade check catch both kinds of mistake (see below).

Option B remains legitimate where the organization deliberately adopts the rule "all workspace-dependent logs go to security unless overridden". In that case, document it as a governance and ownership standard (including budget for the extra ingestion cost), not as protection against forgetting a future assignment.

## Recommended routing (Option A)

| Policy assignment | Parameter | Destination | Duplicate needed? |
| --- | --- | --- | --- |
| `Deploy-AzActivity-Log` | `logAnalytics` | Management (default) plus a second route to security | Yes |
| `Deploy-Diag-LogsCat` | `logAnalytics` | Management (default) plus a duplicate assignment to security | Yes |
| `Deploy-AzSqlDb-Auditing` | `logAnalyticsWorkspaceId` | Management by default; security if SQL auditing is treated as a security-owned signal (decide per policy) | Decide |
| `Deploy-MDFC-Config-H224` | `logAnalytics` | Security. Either an override in the ALZ repo, or handed to the security repo (leaning toward the handover; see "Decided approach") | No |
| `Deploy-MDFC-DefSQL-AMA` | `userWorkspaceResourceId` | Security, applied at every management group where it exists. Same ownership choice as above | No |

## Keeping the routing safe over time

Whichever default is chosen, maintain an explicit routing list in the repository (assignment, parameter, destination workspace, duplicated or not) and review it whenever the ALZ library is updated.

- **Routing table:** keep the table above in the repo as the source of truth.
- **Library upgrade review:** review it on every ALZ library version bump.
- **CI check:** fail the pipeline when the library introduces a workspace-dependent parameter that is not listed in the routing table. This addresses the "we might forget an assignment" concern directly, independent of the default.
- **Security visibility:** give the security team reviewer rights on the routing table, so they can verify that nothing security-relevant is routed elsewhere.
- **Permissions:** confirm that policy-assignment identities have the required permissions on workspaces outside their assignment scope. The Defender for Cloud configuration initiative specifically calls out the need to grant workspace permissions when its target workspace is outside the assignment scope.

## Terraform configuration points

- `policy_default_values` supplies values by library default name. For the shared workspace, use `log_analytics_workspace_id = jsonencode({ value = <management workspace ARM resource ID> })`.
- `policy_assignments_to_modify` can override parameters for individual assignments. Its outer map is keyed by management-group ID and its inner `policy_assignments` map is keyed by assignment name.
- Apply an override at every management-group scope where the relevant policy assignment exists. In particular, check the scopes using `Deploy-MDFC-DefSQL-AMA`.
- The parameter key must match the assignment's parameter exactly, such as `logAnalytics`, `logAnalyticsWorkspaceId`, or `userWorkspaceResourceId`.
- The default Activity Logs assignment routes to one workspace; explicitly configure the second destination if Activity Logs must be present in both.
- The duplicate `Deploy-Diag-LogsCat` assignment is not populated by the shared default. Give it its own name and an explicit workspace value.
- Duplicated diagnostic settings must not collide: resources have a limit on the number of diagnostic settings, and two assignments targeting the same categories need distinct setting names.

## Implementation checklist

- [ ] Set `log_analytics_workspace_id` to the management workspace ARM resource ID in `policy_default_values`.
- [ ] Decide who owns `Deploy-MDFC-Config-H224` and `Deploy-MDFC-DefSQL-AMA`. If the ALZ repo keeps them, override them to the security workspace at every relevant management-group scope. If security takes them over, disable them in the ALZ repo first and agree how security receives the shared AMA inputs.
- [ ] Security repo: define the diagnostic policies for the security workspace and the tenant-level (Entra) diagnostic settings.
- [ ] Agree that no policy is assigned from both repos, and document the ownership table.
- [ ] Decide the destination for `Deploy-AzSqlDb-Auditing`.
- [ ] Create the duplicate `Deploy-Diag-LogsCat` assignment for the security workspace (name, scope, explicit workspace value).
- [ ] Configure the second Activity Log route so both workspaces receive Activity Logs.
- [ ] Grant assignment managed identities the required permissions on the security workspace.
- [ ] Verify the resulting diagnostic settings do not collide.
- [ ] Commit the routing table and add the library-upgrade review step.
- [ ] Add the CI check for new workspace-dependent parameters.
- [ ] Give the security team reviewer rights on the routing table.

## Proposed position for the security team

The security team's underlying need is visibility and assurance that nothing slips through. Offer that directly: the explicit routing table, the library-upgrade review, the CI check, and reviewer rights for security. This addresses the risk without moving away from the ALZ baseline or sending all operational logs to the security workspace.

## References

- [ALZ policy default values](../Azure-Landing-Zones-Library/platform/alz/alz_policy_default_values.json)
- [ALZ policy default values documentation](../Azure-Landing-Zones-Library/docs/content/assets/policy-default-values.md)
- [ALZ Terraform module input documentation](./README.md#input_policy_default_values)
- [Defender for Cloud configuration initiative](../Azure-Landing-Zones-Library/platform/alz/policy_set_definitions/Deploy-MDFC-Config_20240319.alz_policy_set_definition.json)
