# Workspace Routing Inventory as a Control

## Purpose

The shared ALZ workspace default and the routing inventory solve different problems:

- The **default** answers: “If an ALZ policy uses the shared workspace parameter, which workspace does it get?”
- The **routing inventory** answers: “Where is each required log source intended to go, who owns that route, and how do we verify it?”

Keep the management workspace as the shared ALZ default, but do not treat that default as the complete routing policy. The inventory is the record of intended routing; the default is only a fallback for assignments that use the shared parameter.

## Why the default is not enough

A shared default supplies one workspace ID to matching policy parameters. It does not create multiple destinations, establish ownership, or confirm that the policy deployed a working diagnostic setting.

For example, Activity Logs are required in both the management and security workspaces. Setting the shared default to either workspace only configures that destination. A separate route is still needed for the other workspace. Similarly, a newly added workspace-dependent policy could inherit the default without anyone deciding whether that destination is appropriate.

Changing the default to security does not eliminate these risks. It changes which workspace receives an unreviewed route, but it does not ensure that the other workspace receives its required copy.

## What to record

Maintain a reviewed inventory for each workspace-dependent policy or log source. At minimum, record:

| Field | What to capture |
| --- | --- |
| Assignment or source | Policy assignment name or log source |
| Parameter or route | Workspace parameter name or diagnostic-setting route |
| Destination | Management, security, both, or another approved destination |
| Owner | Repository/team responsible for the assignment |
| Duplicate route required? | Whether a second assignment or route is needed |
| Dependencies | Required identity permissions, shared inputs, or other prerequisites |
| Verification | How to confirm the expected diagnostic setting and ingestion |

Example:

| Assignment or source | Parameter or route | Destination | Owner | Duplicate route? | Verification |
| --- | --- | --- | --- | --- | --- |
| `Deploy-AzActivity-Log` | `logAnalytics` | Management and Security | ALZ repo / Security repo, with one owner per assignment | Yes | Confirm Activity Logs arrive in both workspaces |
| `Deploy-Diag-LogsCat` | `logAnalytics` | Management and selected Security categories | ALZ repo / Security repo, with one owner per assignment | Yes, for selected categories | Confirm settings coexist and expected categories arrive |
| `Deploy-MDFC-Config-H224` | `logAnalytics` | Security | Agreed policy owner | No | Confirm export configuration and security-workspace ingestion |

The owner field must identify who actually manages each assignment. If two repositories participate in a dual-destination design, state which repository owns each distinct assignment; do not imply that both repositories own the same assignment.

## Use the inventory in the delivery workflow

### 1. Review library upgrades

Whenever the ALZ library version changes:

- Review new, removed, or changed workspace-dependent assignments and parameters in the pinned version.
- Decide the intended destination, owner, and duplication requirement for each relevant change.
- Update the inventory and Terraform configuration together.
- Confirm that a policy assigned in one repository is not also assigned by another repository.

### 2. Add a CI check

A CI check can make the review enforceable. It should inspect the pinned library version and the assignments enabled by the configuration. Fail the check when an enabled workspace-dependent assignment or parameter has no inventory entry.

The check should validate the actual assignment/parameter relationship rather than searching only for a workspace ID string. A matching string does not prove that the correct assignment uses it, that a required second route exists, or that the assignment is enabled at the intended scope.

The inventory can also be checked for completeness of required fields, such as an owner and a verification method. Keep the check proportionate to the repository: start by detecting unreviewed library changes, then add stronger configuration-to-inventory consistency checks if practical.

### 3. Verify deployed routing

After deployment, verify both configuration and outcome:

- Confirm the policy assignments exist at the intended scopes and point to the intended workspace IDs.
- Confirm assignment identities have the required permissions on destination workspaces.
- For duplicate diagnostic settings, verify names and categories do not collide or overwrite each other, and check resource limits.
- Confirm representative data arrives in every required workspace.

A policy assignment being present is not, by itself, proof that the expected data reached the workspace.

## Operating rule

Use the management workspace as the shared ALZ default. Use explicit inventory entries and routes for security-specific data and for any source that must reach both workspaces. Treat changes to the inventory as part of the same review as changes to Terraform and ALZ library versions.

This makes the routing intent visible and reviewable, while avoiding the assumption that choosing a security-first default is itself a safeguard.

## Full chat response

> A **default value** answers: “If an ALZ policy uses the shared workspace parameter, which workspace does it get?” It does **not** answer: “Are all required logs going to the right workspace, and are both teams receiving the logs they need?”
>
> That’s why I’d keep the management workspace as the shared default, but use an explicit **routing inventory** as the control for the full design. The default is a convenient fallback; the inventory says what the organization actually intends.
>
> ### What the inventory should capture
>
> For each workspace-dependent policy or log source, record:
>
> | Field | Example |
> |---|---|
> | Assignment or source | `Deploy-AzActivity-Log` |
> | Parameter or route | `logAnalytics` |
> | Destination | Management and Security |
> | Owner | ALZ repo / Security repo |
> | Duplicate route required? | Yes |
> | Required permissions or dependencies | Assignment identity needs access to both workspaces |
> | Verification | Confirm both workspaces receive Activity Logs |
>
> The file’s current routing table is a useful starting point. For example, it says Activity Logs should go to management by default **and** have a separate route to security. That requirement is clearer and safer than trying to make one shared default serve two destinations. See [log-analytics-workspace-routing 3.md](<G:/My Drive/Obsidian-Vault/nikkle/Technology/Azure/Logging and Diagnostics/log-analytics-workspace-routing 3.md>).
>
> ### How it becomes a control
>
> Use the inventory in three parts of the workflow:
>
> 1. **During design:** Every workspace-dependent ALZ assignment gets an explicit destination and owner. If a new policy appears during an ALZ library upgrade, the team decides how it should route rather than accepting whatever the default happens to do.
> 2. **During review and deployment:** Review changes to the inventory alongside changes to Terraform and policy assignments. Check that the configured routes match the inventory, including any duplicate assignments and their permissions.
> 3. **During verification:** Confirm the deployed diagnostic settings and actual ingestion match the intended routes. A configured policy assignment alone does not prove that the expected data reached the intended workspace.
>
> A CI check can help catch changes, but it needs to check the **pinned library version** and the actual assignment definitions or parameters—not merely look for a matching string. For example, fail a pull request if an enabled assignment introduces a workspace parameter that is missing from the inventory. Then require an owner to add its routing decision before the upgrade proceeds.
>
> ### Why not use the security workspace as the default as a safety net?
>
> Because the default only changes the fallback destination for a single route. It does not create both copies. With either default, a missed assignment may route to the wrong workspace, and a required second destination can still be forgotten. A reviewed inventory and upgrade check target both problems directly.
>
> So the practical rule is: **use the management workspace as the ALZ shared default, but don’t treat that default as the routing policy. Treat the reviewed inventory—and checks that keep Terraform aligned with it—as the routing policy.**
