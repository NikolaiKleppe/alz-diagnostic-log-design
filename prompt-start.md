# Prompt: Architectural Design – Separation of Operational and Security Diagnostic Logging in Azure

Act as a senior Azure Cloud Architect with deep expertise in Azure Landing Zones (ALZ), Azure Policy, Azure Monitor, Log Analytics, Microsoft Sentinel, and Infrastructure as Code (Terraform).

I am preparing an architectural design document describing how our organisation should separate operational and security diagnostic logging across Azure environments.

Your task is to help me develop a technically accurate, well-structured, and actionable architecture design document, based on the Navigator framework detailed under /skills/.

Additional context and references are under /brainstorming/ and /summaries/.


## 1. Background and context

Our Azure platform is based on the Azure Landing Zones architecture, using the newer modular Azure Verified Modules (AVM) approach and the Azure Landing Zones Policy Library.

We currently have a platform team responsible for the central Azure platform, including:

- Azure Landing Zones and governance.
- Azure Policy and policy assignments.
- Centralised monitoring and operational logging.
- Azure infrastructure and platform automation.

We also have a dedicated security team responsible for security monitoring, incident detection, investigation, and Microsoft Sentinel.

We are evaluating an architecture with two centrally managed Log Analytics workspaces:

1. **Operational workspace:** Owned by the platform team and used for operational monitoring, troubleshooting, and platform observability.
2. **Security workspace:** Owned by the security team and integrated with Microsoft Sentinel, used for security monitoring, threat detection, incident investigation, and relevant compliance requirements.

The intention is to give the security team independent ownership of its workspace, configuration, and diagnostic policy assignments without introducing unnecessary dependencies on the platform team's deployment lifecycle.

## 2. Architectural principles and requirements

The design should account for the following priorities:

- Security isolation between operational and security telemetry.
- Independent ownership and administration of the security workspace by the security team.
- Separate retention requirements and lifecycle management.
- Avoiding unnecessary ingestion and Microsoft Sentinel costs.
- Clear ownership of Azure diagnostic settings and policy assignments.
- Reuse of upstream Azure Landing Zones Policy Library definitions wherever possible.
- Minimal custom policy maintenance and manageable upstream drift.
- Consistent and automated deployment through Infrastructure as Code.
- Avoiding conflicts between independently deployed policy assignments.

Security isolation and independent ownership are particularly important architectural drivers.

## 3. Proposed implementation approach

The current proposed approach is:

- The platform team manages operational diagnostic settings through its existing ALZ repository.
- The security team manages security diagnostic settings through a separate security repository.
- Both repositories independently consume the upstream Azure Landing Zones Policy Library.
- Each team is responsible for its own policy assignments and diagnostic settings.
- Both teams must avoid managing the same diagnostic setting on the same Azure resource.

The security team is considering using the following ALZ policy assignments, among other options:

- `Deploy-AzActivity-Log.alz_policy_assignment.json`
- `Deploy-AzSqlDb-Auditing.alz_policy_assignment.json`
- `Deploy-Diag-LogsCat.alz_policy_assignment.json`

The built-in Azure Policy `allLogs` initiative is also being considered:

- Initiative ID: `0884adba-2312-4468-abeb-5422caed1038`

This initiative exposes a `resourceTypeList` parameter, which allows resource types to be selected. However, it does not allow individual diagnostic categories to be selected within an included resource type. For included resource types, the `allLogs` category group is deployed.

The design should evaluate when to use:

- The upstream `allLogs` initiative with a curated resource type list.
- Individual upstream diagnostic policy definitions for specific categories.
- Custom policy definitions or initiatives when upstream functionality is insufficient.

Any custom policies or initiatives should be kept to a minimum and have a defined process for tracking upstream changes.

## 4. Scope of the design document

The document should cover the following areas:

### Architecture overview
- Describe the proposed architecture and its components.
- Explain the responsibilities of the platform and security teams.
- Describe the relationship between the two Log Analytics workspaces.
- Include architecture diagrams where appropriate.

### Diagnostic logging strategy
- Define the distinction between operational and security logging.
- Describe how Azure resources are assigned to the appropriate workspace(s).
- Identify relevant security log sources and categories.
- Explain how resources that require logging in both workspaces are handled.

### Azure Policy architecture
- Describe the use of the ALZ Policy Library.
- Explain how policy assignments are managed independently by each team.
- Evaluate the use of the `allLogs` initiative and its `resourceTypeList` parameter.
- Explain when individual policies or custom policy definitions are required.
- Address policy versioning, upstream changes, and drift management.

### Ownership and responsibilities
- Define the ownership boundaries between the platform and security teams.
- Explain how diagnostic settings are managed to prevent conflicts.
- Describe how policy changes are reviewed and deployed.

### Security and governance
- Describe workspace access controls and administrative boundaries.
- Address data isolation and retention.
- Explain how the architecture supports security monitoring and incident investigation.

### Cost and operational considerations
- Discuss Log Analytics ingestion and retention costs.
- Consider Microsoft Sentinel ingestion costs.
- Evaluate the operational overhead of maintaining two workspaces and independent policy deployments.

### Alternatives considered
Evaluate at least:
1. A single central Log Analytics workspace shared between platform and security.
2. Two separate workspaces with the platform team managing both.
3. Two separate workspaces with independent platform and security repositories.

Explain the advantages, disadvantages, and trade-offs of each alternative.

## 5. Writing and quality requirements

The document should:

- Use professional architectural language suitable for enterprise architecture review.
- Be technically precise and avoid vague statements.
- Distinguish between confirmed Azure capabilities and architectural recommendations.
- Explain the reasoning behind important design decisions.
- Avoid unnecessary implementation-level detail unless it is relevant to the architecture.
- Use clear headings, tables, and diagrams where appropriate.
- Identify assumptions, dependencies, risks, and unresolved questions.
- Avoid presenting assumptions as established facts.

