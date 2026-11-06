# Azure Landing Zones: Separate Operational and Security Diagnostic Workspaces

## Context and decision

The discussion concerns an Azure Landing Zone (ALZ) deployment using AVM and the ALZ Library.

The central design question is whether all Azure diagnostic
logs---including security-relevant logs---should be sent to one central
Log Analytics workspace integrated with Microsoft Sentinel, or whether
operational and security telemetry should be separated into two
workspaces.

The current direction is to use **two workspaces**:

-   An operational/platform Log Analytics workspace, owned by the
    platform team.
-   A security Log Analytics workspace, owned independently by the
    security team and integrated with Sentinel.

With the additional context provided, this is considered a better fit
than making the platform repository responsible for configuring both
workspaces. The security team can manage its own security assignments
from its own repository while independently consuming the upstream ALZ
Policy Library.

This is an architectural preference, not a claim that two workspaces are
universally required. The separation is justified by the organisation's
ownership, isolation, and retention requirements.

## Why two workspaces are justified

The reasons and their relative importance were described as follows:

  ------------------------------------------------------------------------
  Driver                                  Importance Rationale
  --------------------- ---------------------------- ---------------------
  Security isolation                            High Security telemetry
                                                     and its access
                                                     boundary should be
                                                     isolated from
                                                     ordinary platform
                                                     operations.

  Independent security                          High The security team
  ownership                                          should own its
                                                     workspace and
                                                     Sentinel
                                                     configuration without
                                                     depending on the
                                                     platform team's
                                                     release cycle.

  Different retention                    Medium/high Operational and
  requirements                                       security data can
                                                     have different
                                                     retention,
                                                     investigation, and
                                                     compliance
                                                     requirements.

  Sentinel cost                            Secondary Avoiding Sentinel
                                                     ingestion costs for
                                                     operational logs is
                                                     useful, but is not
                                                     the primary reason
                                                     for separation.
  ------------------------------------------------------------------------

A single workspace could potentially be made to work using table-level
RBAC and carefully managed permissions. However, that can create ongoing
coordination and permission-management overhead. The organisation places
high value on independent security ownership, so the operational
simplicity of one workspace does not necessarily outweigh that cost.

## Repository and ownership model

The proposed model is:

1.  The platform team manages operational diagnostic settings and
    operational policy assignments in the platform ALZ repository.
2.  The security team manages security diagnostic settings and security
    policy assignments in its own security repository.
3.  Both repositories consume the upstream ALZ Policy Library
    independently.
4.  Each repository owns only the diagnostic settings it is responsible
    for.

This is preferable to duplicating or copying the entire ALZ policy
library into separate implementations. The upstream library remains the
common source of policy definitions and initiatives, while each team
selects and configures the relevant assignments for its responsibility.

The security team's independent repository is considered operationally
manageable, provided that ownership boundaries are explicit and the same
diagnostic setting is never managed by both repositories.

### Critical ownership rule

**Do not allow the platform and security repositories to manage the same
diagnostic setting on the same resource.**

Azure diagnostic settings are separate child resources, but policy
definitions can use fixed diagnostic setting names. If two policy
assignments attempt to create or manage a setting with the same name,
they can overwrite or conflict with one another. The fact that the
assignments are deployed from different repositories does not remove
that risk.

Before enabling a policy in both workspaces, verify that the underlying
policy definition supports distinct diagnostic setting names. If it does
not, use a custom policy variant or another supported mechanism to give
each workspace a unique setting name.

## ALZ Library assignments under consideration

The security team is considering three assignments from the ALZ Policy
Library:

1.  `Deploy-AzActivity-Log.alz_policy_assignment.json`
2.  `Deploy-AzSqlDb-Auditing.alz_policy_assignment.json`
3.  `Deploy-Diag-LogsCat.alz_policy_assignment.json`

The first two assignments use policy definitions. The third assignment
references an initiative.

Important implementation detail: assignment-level parameters do not
automatically make every aspect of a diagnostic setting configurable.
The underlying policy definition determines whether the diagnostic
setting name, categories, category groups, and destination are
configurable.

The SQL auditing policy was discussed as an example where the underlying
definition may use a fixed diagnostic setting name:

`SQLSecurityAuditEvents_3d229c42-c7e7-4c97-9a99-ec0d0d8b86c1`

If both the operational and security workspaces need SQL audit events,
verify the exact definition in the ALZ version being consumed. If the
setting name is fixed, a custom variant with a unique setting name may
be necessary. This detail should be checked against the pinned upstream
version rather than assumed to be identical across releases.

## The `Deploy-Diag-LogsCat` / `allLogs` initiative

A discrepancy was identified in the ALZ Library assignment:

-   The assignment description referred to `allLogs`.
-   The referenced initiative ID was reported to be
    `f5b29bc4-feca-4cc6-a58a-772dd5e290a5`, which corresponds to the
    `audit` category-group initiative.
-   The `allLogs` initiative ID is
    `0884adba-2312-4468-abeb-5422caed1038`.

ALZ GitHub issue
[#291](https://github.com/Azure/Azure-Landing-Zones-Library/issues/291)
was referenced in relation to this discrepancy.

The security team is interested in assigning the `allLogs` initiative
as-is. A key question was whether it is possible to select only some
policies or log categories from an initiative, or whether a custom
initiative is required.

### Important capability of the built-in `allLogs` initiative

The current Microsoft built-in `allLogs` initiative definition exposes a
`resourceTypeList` parameter.

The initiative evaluates each policy reference against the resource type
list. If a resource type is not included, the corresponding policy's
effect is set to `Disabled`. This means the upstream initiative can be
used while limiting its scope to a curated list of resource types.

This provides a way to reuse the built-in initiative without creating a
custom initiative merely to exclude entire resource types.

However, this mechanism has an important limitation:

-   `resourceTypeList` selects **resource types**, not individual
    diagnostic categories.
-   For a resource type that is included, the initiative deploys the
    `allLogs` category group.
-   The `allLogs` category group collects all available log categories
    for that resource type.
-   Microsoft can add new categories to a category group over time. As a
    result, the effective set of collected logs can expand when the
    platform's category-group definition changes.

Therefore, `resourceTypeList` is useful for controlling which resource
types send logs to the security workspace, but it does not provide
fine-grained selection of categories within a resource type.

Relevant references discussed:

-   [Microsoft Learn: Azure Policy for diagnostic settings and category
    groups](https://learn.microsoft.com/azure/azure-monitor/platform/diagnostic-settings-policy)
-   [Microsoft built-in `allLogs`
    initiative](https://www.azadvertizer.net/azpolicyinitiativesadvertizer/0884adba-2312-4468-abeb-5422caed1038.html)
-   [Azure Policy repository -- `allLogs` initiative
    definition](https://github.com/Azure/azure-policy)
-   [ALZ Library issue
    #291](https://github.com/Azure/Azure-Landing-Zones-Library/issues/291)

The exact initiative definition and parameters should be verified
against the version currently deployed. The observations above were
based on the current upstream definition reviewed during the discussion,
not necessarily every historical ALZ Library release.

## Recommended policy strategy

A pragmatic approach is to combine the upstream initiative with
individual policies and narrowly scoped custom policies.

### 1. Use the upstream `allLogs` initiative where appropriate

Use the built-in `allLogs` initiative with a curated `resourceTypeList`
for resource types where collecting all available diagnostic categories
is justified for security monitoring or investigation.

This retains upstream policy maintenance and reduces the need to
maintain a custom initiative.

Do not automatically include every supported resource type. Each type
should have a documented security monitoring, investigation, or
compliance rationale.

### 2. Use individual policies for selective categories

Where only specific categories are needed, use individual upstream
policy definitions rather than the `allLogs` initiative.

For example, SQL Security Audit Events may be valuable to the security
team, while database performance and troubleshooting categories may be
more appropriate for the operational workspace.

This avoids sending all categories from a resource type to the security
workspace when only a subset is required.

### 3. Create custom policy variants only when necessary

Use a custom policy definition when the upstream definition does not
expose the configuration needed to maintain the intended
separation---for example, where a diagnostic setting name is fixed and
the same resource must send data to two workspaces.

Keep customizations as small as possible:

-   Reuse the upstream policy definition as the baseline.
-   Change only the required parameter, diagnostic setting name,
    category selection, or other necessary behaviour.
-   Document the reason for the customization.
-   Track the upstream definition and review changes during ALZ
    upgrades.

### 4. Avoid copying the whole initiative without a maintenance mechanism

A custom initiative can provide precise control over its included policy
references, but it introduces drift risk. New or updated policy
references in the upstream initiative do not automatically appear in the
custom initiative.

If a custom initiative is needed, treat it as a controlled derivative of
the upstream initiative:

-   Maintain an explicit allowlist of policy definition reference IDs.
-   Generate or update the custom initiative from the upstream
    definition where feasible.
-   Compare the custom initiative with the upstream initiative during
    upgrades.
-   Review newly added, changed, and removed policy references.
-   Record why each policy is included or excluded.

This makes drift visible and reviewable instead of allowing an unmanaged
fork to develop.

### 5. Consider effect overrides only as a secondary option

Initiative assignment effect overrides may be able to disable selected
policy references while retaining the upstream initiative. This can be
useful where the required selection is supported by the initiative's
policy reference IDs and the relevant Azure Policy functionality.

However, the policy references remain part of the initiative; they are
simply disabled for that assignment. This can make the effective
configuration less obvious to operators and reviewers.

For a clear, intentional security policy baseline, a custom initiative
with a documented allowlist may be easier to understand when
fine-grained policy selection is required. Verify the supported
effect-override syntax and behaviour for the specific initiative and
Azure Policy API/version before adopting it.

Policy exemptions are generally not the preferred way to prune a
baseline. They are better suited to documenting a justified exception to
an otherwise applicable policy.

## Log selection: security versus operations

The distinction should be based on security use cases, not simply on
whether a log is technically available.

### Security-relevant log sources to consider

Examples include:

-   Microsoft Entra ID sign-in logs and audit logs, including service
    principal sign-ins.
-   Azure Activity Log, especially control-plane operations, role
    assignments, policy changes, and other administrative activity.
-   Key Vault audit events.
-   SQL Security Audit Events.
-   Azure Firewall network, application, and threat-intelligence logs.
-   Application Gateway WAF logs.
-   Azure Front Door WAF and other security events.
-   Storage read, write, and delete operations for sensitive data
    stores.
-   NSG flow logs, where supported and justified.
-   Azure Container Registry authentication and audit events.
-   AKS Kubernetes API audit logs and relevant control-plane logs.

Not all of these sources are necessarily configured through Azure
resource diagnostic settings. For example, Entra ID logs and some
Defender data sources use separate collection and integration
mechanisms.

### Examples of logs that are often primarily operational

These may be excluded from the security workspace unless a specific
detection, investigation, or compliance requirement justifies collecting
them there:

-   App Service HTTP, console, and application logs.
-   Azure Functions execution and application logs.
-   Container Apps console and system logs.
-   API Management gateway logs.
-   Application Gateway access logs (distinguish these from WAF logs).
-   Data Factory pipeline, activity, and trigger execution logs.
-   Databricks cluster and job execution logs.
-   Azure Batch task and job logs.
-   Stream Analytics runtime diagnostics.
-   SQL performance and troubleshooting categories such as SQLInsights,
    AutomaticTuning, QueryStoreRuntimeStatistics,
    QueryStoreWaitStatistics, DatabaseWaitStatistics, Errors, Timeouts,
    and Blocks.
-   Redis performance and connection logs.
-   Communication Services operational logs.
-   Azure AI request and operational logs.
-   Azure Automation job streams and execution logs.
-   Chaos Studio experiment execution logs.

These are examples, not universal exclusions. Operational logs can be
valuable during a security investigation, and some access or gateway
logs can have security value. The security team should document the use
case before excluding them.

## Retention and ingestion considerations

Separate workspaces allow the teams to define different retention and
ownership models. They also make it easier to keep the security team's
Sentinel data scope focused.

It is useful to distinguish between:

-   **Detection data:** logs that Sentinel analytics rules and other
    detections actively use.
-   **Investigation data:** logs needed to investigate incidents and
    establish timelines.
-   **Forensic/compliance retention:** data retained for a longer period
    even if it is not continuously used by detections.
-   **Operational telemetry:** logs used by platform and service teams
    for reliability, troubleshooting, and performance.

Not every log source needs the same ingestion and retention treatment. A
broad `allLogs` deployment across every resource type can create
unnecessary ingestion, noise, and cost. The selected resource types and
categories should have an explicit purpose.

## Practical implementation checklist

Before implementing the split:

1.  Confirm the exact ALZ Library tag/version and the exact upstream
    policy and initiative definitions being consumed.
2.  Verify the `allLogs` initiative ID and its `resourceTypeList`
    behaviour in that version.
3.  Build and review a curated security `resourceTypeList`.
4.  Identify resource types where only selected categories are required;
    use individual policies for these rather than `allLogs`.
5.  Inspect each policy definition for fixed diagnostic setting names
    and hard-coded categories.
6.  Ensure platform and security assignments use unique diagnostic
    setting names whenever both send data from the same resource.
7.  Define repository ownership so each diagnostic setting has exactly
    one owner.
8.  Document security use cases for included resource types and
    categories.
9.  Define retention and access controls independently for the two
    workspaces.
10. Review changes to upstream ALZ policies and Azure category groups
    during upgrades.
11. If maintaining a custom initiative, automate or formalize comparison
    against the upstream initiative.
12. Test policy deployment and remediation on representative resources
    before broad assignment.

## Overall conclusion

The organisation's high priority on security isolation and independent
security ownership supports a two-workspace design. The security team
managing its own assignments from a separate repository is a reasonable
and maintainable approach, provided both teams consume the upstream ALZ
Library consistently and have clear ownership boundaries.

The preferred policy approach is not to fork the entire ALZ library.
Instead:

-   Use the upstream `allLogs` initiative with a curated
    `resourceTypeList` for resource types where all categories are
    appropriate.
-   Use individual upstream policies when only selected categories are
    needed.
-   Create small custom policy variants when upstream definitions
    prevent independent diagnostic settings or the required category
    selection.
-   Maintain any custom initiative as a tracked derivative of upstream,
    with explicit comparison during upgrades.

The most important operational safeguard is to ensure that the platform
and security repositories never compete to manage the same diagnostic
setting. This ownership boundary, combined with a deliberate security
log allowlist and upstream policy tracking, provides a workable balance
between independent team ownership and manageable ALZ drift.
