# Design Decision Patterns

Templates and examples for writing Navigator design decisions.

## Decision Structure

Every decision follows this pattern:

```markdown
### [Section Topic]

[Context and explanation paragraph(s) that build the case for the decision.
This text should logically lead to the decision. The reader should be able
to predict the decision from reading this text.]

**DECISION [PREFIX][NUMBER]: [Clear, actionable statement]**
- [Argument derived from preceding text]
- [Second argument if needed]

☑ Security Impact: [2-3 sentence description: First sentence states the threat/risk mitigated. Second sentence describes the security property achieved. Optional third sentence adds critical context.]
```

## Prefixes by Domain

| Domain | Prefix | Example |
|--------|--------|---------|
| Network | NET | NET01, NET02 |
| Security | SEC | SEC01, SEC02 |
| Identity | ID | ID01, ID02 |
| Storage | STO | STO01, STO02 |
| Compute | COM | COM01, COM02 |
| Database | DB | DB01, DB02 |
| Application | APP | APP01, APP02 |
| Integration | INT | INT01, INT02 |
| Monitoring | MON | MON01, MON02 |
| General | DD | DD01, DD02 |

## Decision Writing Rules

1. **Decide what IS, not what is NOT**
   - "The solution uses Azure AD for authentication"
   - Not: "The solution does not use on-premises AD"

2. **Arguments trace to preceding text**
   - Every bullet point should reference something explained above
   - Reader should not encounter new information in arguments

3. **One decision per choice**
   - Split compound decisions into separate ones
   - Each decision should be independently reviewable

4. **Clear and unambiguous**
   - Avoid words like "might", "could", "possibly"
   - State the decision definitively

5. **Security impact description**
   - Required when decision affects: authentication, authorization, encryption, network exposure, data handling
   - Format: `☑ Security Impact: [Description]` on the same line with colon
   - Content: Include both the threat mitigated AND the security property achieved
   - Length: 2-3 sentences (moderate detail explaining threat + mitigation)
   - First sentence: State the primary threat or risk prevented
   - Second sentence: Describe the positive security outcome established
   - Optional third sentence: Add critical context (GDPR, Zero Trust, threat model references)

## Examples

### Good Decision Example

```markdown
### Authentication Method

The customer environment requires single sign-on capability for all users
accessing the management portal. Azure Active Directory is already established
as the identity provider across the organization. Using Azure AD enables
seamless integration with existing user accounts and leverages the customer's
investment in conditional access policies.

**DECISION ID01: Azure Active Directory is used for authentication to the management portal**
- Enables single sign-on with existing user accounts
- Leverages established conditional access policies

☑ Security Impact: Prevents unauthorized access through centralized identity verification and multi-factor authentication enforced by Azure AD. Establishes secure authentication with conditional access policies that dynamically evaluate user context, device compliance, and risk signals before granting access.
```

### Bad Decision Example (and corrections)

```markdown
### Authentication Method

We will probably use Azure AD for authentication.

**DECISION ID01: We might use Azure AD or maybe on-premises AD**
- It seems like a good idea
- The customer has it already
```

**Problems:**
- Uses "we" (should be impersonal)
- Uses uncertain language ("probably", "might", "maybe")
- Arguments don't derive from text
- Decision is not clear

## Decision Categories

### Technology Selection
Selecting specific products, platforms, or technologies.
```
**DECISION COM01: VMware vSphere 8.0 is used as the virtualization platform**
```

### Configuration Choice
Specific settings or parameters.
```
**DECISION NET03: VLAN 100 is assigned to management traffic**
```

### Architecture Pattern
High-level structural decisions.
```
**DECISION APP02: The application follows a three-tier architecture pattern**
```

### Integration Approach
How systems connect and communicate.
```
**DECISION INT01: REST APIs are used for all service integrations**
```

### Security Control
Security-related implementations.
```
**DECISION SEC05: All data at rest is encrypted using AES-256**
```

## Traceability

Decisions should trace to requirements. In the design document summary:

| Requirement ID | Description | Decision(s) | Status |
|----------------|-------------|-------------|--------|
| REQ-001 | SSO for portal | ID01 | Fulfilled |
| REQ-002 | HA for database | DB01, DB02 | Fulfilled |
