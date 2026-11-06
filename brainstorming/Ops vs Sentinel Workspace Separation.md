Topic:
* https://techcommunity.microsoft.com/blog/azuregovernanceandmanagementblog/a-new-platform-management-group--subscription-for-security-in-azure-landing-zone/4433287
## Claude

* Conversation
	* https://claude.ai/chat/56648c99-8027-413f-ad5a-c10f7edd1392
* Prompt:

```
Azure Landing Zones and Terraform. (Using AVM modules and the ALZ Library).

We want to use two log analytics workspaces, one for management (alz-management MG), and one for security logging. We wonder if we should keep the ALZ default of sending ALZ logs to the central management workspace or to the security workspace. For example, both workspaces needs activity logs, but only security workspace needs defender for cloud logs.

For policies like Deploy-Diag-LogsCat we plan to create a duplicate assignment, one for management and one for security

The security team argues that the default should be to send all log policies to the security workspace, in case we forget or miss any assignments that depends on a workspace. Then the for management it needs to be explicitly duplicated.
I have mixed opinions on it, there are only a couple of assignments that are relevant and it's not much work to define that once in the code. We try to follow the intended ALZ configuration/architecture

I have attached a document detailing the arguments
```

* ![[log-analytics-workspace-routing 3]]

## Gemini

Conversation
* https://gemini.google.com/app/1d3f35a658cfd584

* Prompt

```
Azure Landing Zones - Ops Logging vs Security Logging, separate workspaces?

We're implementing ALZ, with Terraform and AVM modules. Large enterprise customer.

We're discussing the approach for Log Analytics Workspaces and logging. If we should either:
	1) Go with the default CAF recommendation of using one central LAW and route all logs to it, and then enable Sentinel on that workspace, or:
	2) One LAW for operations, and one LAW for Security. Then enable Sentinel on the Security Workspace.

As per the new ALZ recommendations, we would place this security LAW in the Security Subscription in the platform archetype.

The AVM ALZ module establishes the first option today: a single workspace, and all policies points to that workspace.

Benefits of 1:
	* Simplicity, no need to duplicate policy assignments for diagnostic logging
Downsides of 1:
	* Increased cost (most likely), as Sentinel bills every log in the workspace, including non-relevant logs such as performance, health logs, and metrics
	* Need to use table-level RBAC to prevent read access to security-sensitive logs


Benefits of 2:
	* Complete separation of duty. Security team owns their own workspace.
	* Only relevant logs are sent to LAW and processed by Sentinel, less noise
	* Potentially reduced cost if logs are properly enabled where relevant (even though some logs will be sent to both workspaces)
Downsides of 2:
	* Need to duplicate policy assignments for diagnostic settings, most of which are a part of the ALZ Library
	* Probably need to customize/tune some of the policy initiatives, as they might send too much operational logs

References:
* https://techcommunity.microsoft.com/blog/azuregovernanceandmanagementblog/a-new-platform-management-group--subscription-for-security-in-azure-landing-zone/4433287
* https://learn.microsoft.com/en-gb/azure/azure-monitor/logs/workspace-design#operational-and-security-data
* https://github.com/Azure/Enterprise-Scale/discussions/1978
```


### Response

For a large enterprise customer implementing ALZ with Terraform and Azure Verified Modules (AVM), choosing between a single combined workspace (Option 1) and separate workspaces for operations and security (Option 2) is one of the most critical architectural decisions you will make.

While the AVM ALZ modules default to Option 1 out-of-the-box for simplicity, large enterprises frequently migrate to or opt for Option 2 due to strict organizational boundaries, cost dynamics, and compliance demands.

#### Why Option 1 (Single Workspace) often breaks down in Large Enterprises:

1. **The Sentinel "Noise" Tax:** Microsoft Sentinel bills you for ingestion. If you stream massive amounts of standard application diagnostics, performance metrics, and infrastructure health logs into a Sentinel-enabled workspace, you pay the Sentinel ingestion rate on data your SOC will never look at.

2. **Political & Organizational Friction:** In large enterprises, the **Central Operations/Platform Team** and the **Security Operations Center (SOC)** are often separate silos (sometimes even managed by different third-party vendors or internal departments). Getting SecOps to share a workspace with Ops—or forcing Ops to accept security oversight on their operational telemetry—frequently triggers governance standoffs.

3. **Table-Level RBAC Overhead:** Securing a single workspace requires managing granular Azure Monitor Workspace-centric permissions (Log Analytics Reader + Data Actions restrictions). It is prone to configuration drift and audit friction compared to giving the SOC an isolated subscription.

#### Why Option 2 (Separate Workspaces) aligns with the New ALZ Guidance:

Microsoft's introduction of the **Security Platform Management Group / Subscription** archetype specifically validates the separation of security infrastructure from general management/operations.

- **True Least Privilege:** Your SOC gets full administrative control over the Security Subscription and its LAW, without having visibility into or administrative touchpoints on general operational data that they shouldn't care about (and vice versa).

- **Targeted Ingestion:** You can use DCRs (Data Collection Rules) to send heavy performance or debugging logs exclusively to the Ops LAW (retained cheaply or with standard Azure Monitor retention) while streaming security events (Activity logs, Azure Firewall, NSG flow logs, Defender data) to the Security LAW.