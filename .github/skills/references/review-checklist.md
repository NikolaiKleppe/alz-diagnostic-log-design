# Design Review Checklist

Guide for providing constructive feedback on Navigator design documents.

## Constructive Feedback Approach

Navigator emphasizes constructive feedback that:
- Points out what needs to be changed
- Explains why it should be changed
- Suggests how to improve
- Includes praise for good work

**Frame feedback as suggestions, not criticisms. Help the author improve.**

## Review Checklist

### 1. Document Structure

- [ ] Introduction clearly states purpose and target audience
- [ ] Assumptions are documented
- [ ] Scope and out-of-scope are defined
- [ ] Conceptual -> Logical -> Detailed flow is maintained
- [ ] Version history is present

**Questions to ask:**
- Can a reader understand the purpose within the first paragraph?
- Are there any hidden assumptions that should be explicit?

### 2. Writing Quality

- [ ] Written in present tense
- [ ] Impersonal voice (no I/we/you/they)
- [ ] Information presented in logical order
- [ ] No unnecessary technology explanations
- [ ] Spelling and grammar correct
- [ ] Abbreviations defined on first use

**Questions to ask:**
- Would this text make sense if read out of order?
- Is there any text that doesn't support a decision?

### 3. Design Decisions

- [ ] All significant choices have decisions
- [ ] Decisions focus on what IS (not what is not)
- [ ] Arguments derive from preceding text
- [ ] Decisions are clear and unambiguous
- [ ] Security impact noted where relevant
- [ ] Decision IDs follow naming convention

**Questions to ask:**
- Could someone implement this without asking clarifying questions?
- Are there implicit decisions that should be explicit?

### 4. Requirement Coverage

- [ ] All requirements addressed
- [ ] Requirements linked to decisions
- [ ] Traceability table complete
- [ ] No requirements without corresponding design content

**Questions to ask:**
- Can every requirement be traced to specific design content?
- Are there design elements without corresponding requirements?

### 5. Diagrams

- [ ] Diagrams complement text (not duplicate)
- [ ] Simple shapes used (no server icons in conceptual)
- [ ] Objects aligned and evenly distributed
- [ ] Consistent color usage
- [ ] Numbered objects use n1, n2, n3 convention
- [ ] Each diagram has clear purpose
- [ ] No copied/copyrighted images

**Questions to ask:**
- Does removing any element change the message?
- Could this diagram be misinterpreted?

### 6. Reusability

- [ ] Could this design be applied to similar projects?
- [ ] Standard Navigator templates used
- [ ] Visio follows Word (same naming)
- [ ] Diagrams in reusable format

**Questions to ask:**
- What would need to change to reuse this for another customer?
- Are there project-specific details that should be generalized?

### 7. Completeness

- [ ] All sections filled in
- [ ] No placeholder text remaining
- [ ] Help text removed (red text in template)
- [ ] Terms and abbreviations table complete
- [ ] Figures and tables numbered correctly

## Feedback Template

When providing feedback, structure it as:

```markdown
## Design Review: [Document Name]

### Strengths
- [Specific positive observation]
- [Another strength]

### Suggestions for Improvement

#### [Section/Area]
**Observation:** [What was noticed]
**Suggestion:** [How to improve]
**Example:** [Concrete example if helpful]

#### [Another area]
...

### Questions for Clarification
- [Question that would help understand the design better]

### Overall Assessment
[Brief summary of document readiness and recommended next steps]
```

## Version-Specific Reviews

### Version 0.25 Review (Checkpoint)
- Focus on: Structure, concept clarity, chapter outline
- Lighter touch on: Details, exact wording

### Version 0.50 Review (QA)
- Comprehensive review using full checklist
- Document should be "content complete"
- Focus on quality and Navigator compliance

### Version 0.95 Review (Pre-Customer)
- Final polish
- Verify all previous feedback addressed
- Check professional presentation

## Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Decisions not traceable | Add argument bullets that reference text |
| Future tense used | Find/replace "will be" -> "is" |
| Personal pronouns | Rewrite using passive voice |
| Diagrams misaligned | Use Visio align/distribute (F8) |
| Missing decisions | Review each section for implicit choices |
| Technology over-explained | Keep only text that supports decisions |
