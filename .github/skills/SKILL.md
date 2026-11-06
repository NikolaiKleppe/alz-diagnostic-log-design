---
name: navigator
description: "Sopra Steria Navigator methodology skill for design work. Use for: creating design documents (conceptual, logical, detailed), writing design decisions with proper argumentation, reviewing designs with constructive feedback, brainstorming solution architecture, requirement traceability discussions, and creating technical diagrams. Triggers include: 'Navigator', 'design document', 'design decision', 'solution design', 'technical architecture', 'conceptual design', 'logical design', 'detailed design', 'work package', design reviews, or Sopra Steria methodology references. Primarily supports Technical Architect and Solutions Architect roles."
compatibility: Claude Code, GitHub Copilot CLI, OpenAI Codex (via openskills)
---

# Navigator Design Skill

Support for Sopra Steria's Navigator Transformation methodology, focused on Technical Architect and Solutions Architect roles.

## Quick Reference

| Task | Action |
|------|--------|
| Brainstorm design | Structured discovery, propose alternatives with trade-offs, get approval before drafting |
| Write design content | Draft in markdown first, use present tense, impersonal style |
| Create design decisions | Follow decision pattern with clear argumentation |
| Review design | Use constructive feedback checklist |
| Create final document | Use docx skill with Navigator template from `assets/` |
| Create diagrams | Use the **draw-io** plugin for comprehensive diagrams (Azure icons, adaptive interview). For quick inline diagrams, see `references/drawio-guide.md` |
| Convert existing design to markdown | Convert .docx to markdown with pandoc, extract images to `/media`, extract comments to `comments.md`, convert EMF/WMF to PNG, recreate diagrams with **draw-io** plugin |

## Design Document Workflow

### Phase 1: Discovery and Design Exploration

**When to activate:** Enter Phase 1 when the user asks to create a design, explore options, or when the task is vaguely defined and multiple valid architectural approaches exist. Also enter this phase when requirements are incomplete or conflicting.

**Step 1: Explore context first**
Before asking any questions, review what is already available:
- Read existing project files, requirement documents, and prior designs in the workspace
- Check for existing Navigator documents that could be reused or extended
- Summarize what you already know so the user does not have to repeat it

**Step 2: Structured discovery (one question at a time)**
Ask focused questions in this order. Ask one question per message. Use multiple-choice format when feasible to reduce cognitive load.
1. **Business context**: What is the business driver or problem being solved?
2. **Functional requirements**: What must the solution do? (capabilities, user workflows)
3. **Non-functional requirements**: Performance, availability, scalability, security targets
4. **Constraints**: Technical (existing platforms, standards), organizational (team skills, timelines), regulatory (GDPR, sector rules)
5. **Existing systems**: What systems must be integrated? What is the current state?
6. **Success criteria**: How will the design be evaluated? What does "good enough" look like?

See `references/discovery-guide.md` for the full question framework and examples.

**Step 3: Propose architectural alternatives**
Before committing to a direction, present 2-3 alternative approaches:
- Name each alternative clearly
- State the trade-offs (cost, complexity, risk, time-to-deliver, reuse potential)
- Map alternatives to Navigator design levels (conceptual/logical/detailed impact)
- Give a clear recommendation with reasoning
- Strip unnecessary features ruthlessly -- favor the simplest option that meets requirements

**Step 4: Approval gate**
Present the recommended approach and scope summary. Ask the user to confirm before proceeding.

> **Hard rule: Do NOT begin Phase 2 (drafting) until the user has explicitly approved the design direction and scope.**

Scale detail to complexity:
- Simple/well-understood designs: Brief discovery, 1-2 questions, lightweight alternatives
- Complex/ambiguous designs: Full discovery sequence, detailed alternatives, written scope summary

### Phase 2: Drafting in Markdown

Write all design content in markdown first. This allows for rapid iteration and review before finalizing.

**Writing Rules:**
- **Present tense**: "The system uses..." not "The system will use..."
- **Impersonal**: Never use "I", "we", "you", "they" -- use passive voice
- **Structured flow**: Present information in logical order (concept -> details)
- **Technology explanations**: Only include if supporting a design decision

**Document Structure:**
```
1. Introduction (purpose, assumptions, scope, out-of-scope)
2. Summary (requirements table, decisions list, advisory list)
3. Conceptual Design (high-level, abstract, technology-agnostic)
4. Logical Design (components, interfaces, technology choices)
5. Detailed Design (configuration, tables, specifics)
```

### Phase 3: Design Decisions

Every significant choice requires a documented decision. See `references/decision-patterns.md` for templates.

**Decision Format:**
```markdown
### [Topic]

[Explanatory text building the case...]

**DECISION [ID]: [Clear statement of what IS decided]**
- [Argument 1]
- [Argument 2]
```

**Decision Rules:**
- Focus on what IS, not what is NOT
- Arguments must come from the preceding text
- One decision per significant architectural choice
- Security impact should be noted where relevant

### Phase 4: Review and Feedback

When reviewing designs, use constructive feedback approach. See `references/review-checklist.md`.

**Review Focus Areas:**
1. Clarity and completeness
2. Decision quality and traceability
3. Requirement coverage
4. Diagram accuracy
5. Reusability potential

### Phase 5: Final Document Creation

When design is ready for finalization:

1. Use the docx skill (must be installed separately, e.g. from the `anthropics/skills` marketplace) to convert markdown to Word format
2. Use Navigator template from `assets/Navigator_Design_Template.docx`
3. Follow version management: draft -> 0.50 (QA) -> 0.95 (customer) -> 1.00 (approved)

### Converting Existing Designs to Markdown

When an existing .docx design document needs to be converted back to markdown for editing:

**Prerequisites:** Verify pandoc and LibreOffice are installed:
- `pandoc --version` (required for .docx to markdown conversion)
- `soffice --version` (required for EMF/WMF image conversion)

**Step 1: Convert .docx to markdown with image and comment extraction**
```bash
pandoc input.docx --wrap=none -t gfm --extract-media=./media --track-changes=all -o output.md
```
This extracts all embedded images to a `./media` folder, preserves reviewer comments as annotated spans, and generates GitHub-Flavored Markdown with correct image references.

**Step 2: Extract comments to `comments.md`**
Parse the pandoc output for comment spans (format: `[Comment text]{.comment-start id="0" author="Name" date="..."}`) and collect them into a separate `comments.md` file organized by the heading/section where each comment appears:

```markdown
# Comments from [Document Name]

## Section: [Heading where comment was found]
- **[Author]** ([date]): [Comment text]
  > Commented on: "[quoted text that was commented]"
```

Then remove the comment span markup from the main markdown file to produce clean markdown.

**Step 3: Convert EMF/WMF images to PNG**
Word documents often contain EMF/WMF vector images that render poorly outside Word. Convert them:
```bash
cd media && for f in *.emf *.wmf; do [ -f "$f" ] && soffice --headless --convert-to png "$f" && rm "$f"; done && cd ..
```
Then update image references in the markdown file from `.emf`/`.wmf` to `.png`.

**Step 4: Recreate diagrams with draw-io plugin**
For each extracted image that represents a diagram, invoke the **draw-io** plugin to replicate it as a `.drawio` file. The replicated diagram faithfully reproduces the original layout, shapes, labels, and connections. Save recreated diagrams alongside the markdown following the naming convention: `DocumentName.drawio`. Update image references in the markdown to point to exported PNG/EMF from the new `.drawio` files.

**Step 5: Verify and clean up**
- Confirm all image links in the markdown resolve correctly
- Remove orphaned original images that have been recreated as draw.io diagrams
- Review the markdown structure matches the Navigator document structure (Introduction, Summary, Conceptual/Logical/Detailed Design)

## Design Levels

### Conceptual Design
- Abstract, technology-agnostic view
- Simple shapes only (no server icons)
- Target: Decision makers with basic technical understanding
- Focus: The "what" and "why"

### Logical Design
- Technology and component selections
- Interfaces and dependencies shown
- Reuse conceptual diagrams, add detail
- Target: Technical decision makers and developers
- Focus: The "how" at system level

### Detailed Design
- Configuration specifics, often in tables
- All component details
- Basis for system documentation
- Target: Developers and operators
- Focus: The "how" at implementation level

## Diagrams

For comprehensive diagram creation (Azure architecture icons, adaptive user interview, icon lookup, full verification), use the **draw-io** plugin. It handles all diagram types: context, system, component, deployment, data flow, and sequence diagrams.

For quick inline diagrams within a design document, see `references/drawio-guide.md` for basic draw.io XML patterns and Sopra Steria styling.

**Diagram Rules:**
- Simple shapes preferred at conceptual level (boxes, circles, arrows)
- Azure icons appropriate at logical and detailed levels (use draw-io plugin)
- No copied/copyrighted images
- Consistent color palette (Sopra Steria colors)
- Objects aligned and evenly distributed
- Use `n1, n2, n3...` for numbered objects
- One diagram per concept

## References

- `references/discovery-guide.md` - Discovery question framework and alternative-proposal templates
- `references/decision-patterns.md` - Decision writing templates and examples
- `references/review-checklist.md` - Design review checklist
- `references/drawio-guide.md` - Quick draw.io XML patterns and Sopra Steria styling
- **draw-io** plugin - Comprehensive diagram creation with Azure icons, icon lookup, and adaptive interview

## Assets

- `assets/Navigator_Design_Template.docx` - Word template for final documents
- `assets/Navigator_Design_Template.dotx` - Word template (dotx format)
