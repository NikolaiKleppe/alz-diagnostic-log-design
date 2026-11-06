# Design Discovery Guide

Framework for structured discovery and design exploration in Navigator projects.

## Purpose

This guide supports Phase 1 of the Navigator design workflow. It provides
question frameworks, alternative-proposal templates, and examples to ensure
thorough exploration before committing to a design direction.

## Discovery Question Framework

Ask questions in this order. Skip or abbreviate categories when the answer
is already known from project context.

### 1. Business Context

| Question | Purpose |
|----------|---------|
| What business problem or opportunity drives this design? | Ensures design is outcome-oriented |
| Who are the stakeholders and decision makers? | Identifies approval chain and audience |
| What is the timeline and urgency? | Constrains solution space appropriately |
| Is this a new capability or a change to an existing system? | Determines reuse vs. greenfield approach |

### 2. Functional Requirements

| Question | Purpose |
|----------|---------|
| What are the primary user workflows or use cases? | Defines scope boundaries |
| What data is produced, consumed, or transformed? | Identifies data flows and storage needs |
| What integrations are required (APIs, file transfers, events)? | Maps system boundaries |
| Are there requirements from prior Navigator documents to trace? | Ensures continuity |

### 3. Non-Functional Requirements

| Question | Purpose |
|----------|---------|
| What are the availability and recovery targets (RTO/RPO)? | Drives HA and DR decisions |
| What are the performance expectations (users, throughput, latency)? | Sizes the solution |
| What are the security and compliance requirements? | Identifies security controls early |
| What are the scalability expectations (growth over 1-3 years)? | Prevents premature optimization or under-sizing |

### 4. Constraints

| Category | Example Questions |
|----------|-------------------|
| Technical | What platforms, tools, or standards are mandated? What is already in production? |
| Organizational | What skills does the team have? What is the operations model? |
| Regulatory | GDPR, sector-specific regulations, data residency requirements? |
| Financial | Budget constraints, licensing models, cost targets? |

### 5. Existing Systems

| Question | Purpose |
|----------|---------|
| What is the current-state architecture? | Establishes baseline |
| What integration points exist (and which are fragile)? | Identifies risk areas |
| Are there existing Navigator designs to reuse or reference? | Maximizes reuse |
| What technical debt or known issues affect the design? | Avoids building on weak foundations |

### 6. Success Criteria

| Question | Purpose |
|----------|---------|
| How will the design be evaluated at QA review (v0.50)? | Aligns with Navigator lifecycle |
| What would cause the customer to reject the design? | Identifies must-haves vs. nice-to-haves |
| What is the definition of "good enough" for this iteration? | Prevents over-engineering |

## Asking Questions Effectively

**Rules:**
- Ask one question per message (prevents cognitive overload)
- Offer multiple-choice options when the answer space is bounded
- Summarize what you know before asking (shows progress, avoids repetition)
- If the user says "I don't know", suggest reasonable defaults and move on
- Adapt depth to complexity: skip questions when answers are obvious

**Multiple-choice example:**
```
Based on the availability requirement, there are three common patterns:

a) **Active-passive failover** -- simpler, lower cost, brief downtime during failover
b) **Active-active clustering** -- higher availability, more complex, higher cost
c) **Cloud-native PaaS with built-in HA** -- least operational overhead, platform dependency

Which best fits, or would you like to discuss trade-offs?
```

## Proposing Alternatives

Present 2-3 alternatives using this structure:

```markdown
## Design Alternatives

### Alternative A: [Name]
**Summary:** [1-2 sentences]
**Strengths:** [bullet list]
**Weaknesses:** [bullet list]
**Navigator impact:** [Which design levels are affected: conceptual/logical/detailed]
**Estimated complexity:** [Low / Medium / High]

### Alternative B: [Name]
...

### Recommendation
[Name of recommended alternative] is recommended because:
- [Reason 1]
- [Reason 2]
- [Trade-off acknowledged]
```

**Rules for alternatives:**
- Always include at least one simpler option (ruthless feature stripping)
- Be explicit about what each alternative does NOT include
- Map trade-offs to things the stakeholders care about (cost, time, risk, compliance)
- If one alternative is clearly superior, say so -- do not present false balance

## Approval Gate

Before moving to Phase 2, present a scope summary for approval:

```markdown
## Design Scope Summary

**Design title:** [Working title]
**Design level:** [Conceptual / Logical / Detailed]
**Chosen approach:** [Name of selected alternative]
**In scope:**
- [Item 1]
- [Item 2]

**Out of scope:**
- [Item 1]
- [Item 2]

**Key decisions to be made:**
- [Decision topic 1]
- [Decision topic 2]

**Assumptions:**
- [Assumption 1]

Please confirm this scope before I begin drafting.
```

## Scaling to Complexity

| Complexity | Discovery depth | Alternatives | Approval gate |
|------------|----------------|--------------|---------------|
| Simple (well-understood, single component) | 1-2 questions, brief | Optional (1 approach may suffice) | Verbal confirmation |
| Medium (multiple components, some unknowns) | 3-4 key questions | 2 alternatives with trade-offs | Written scope summary |
| Complex (cross-domain, many stakeholders, regulatory) | Full discovery sequence | 2-3 detailed alternatives | Full scope summary with sign-off |

## Common Discovery Pitfalls

| Pitfall | Remedy |
|---------|--------|
| Jumping to solution before understanding the problem | Complete business context and functional requirements before proposing anything |
| Asking too many questions at once | One question per message, multiple-choice when feasible |
| Ignoring existing designs and context | Always scan workspace for existing Navigator documents first |
| Presenting alternatives without a recommendation | Always state which alternative is recommended and why |
| Over-engineering simple designs | Apply ruthless feature stripping; favor simplest viable option |
| Skipping approval gate | Never begin drafting until user confirms direction |
