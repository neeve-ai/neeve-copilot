---
name: to-spec
description: >
  Turn an ADR, feature request, bug report, incident, rough idea, or implementation note into a
  human-consumable engineering spec in the Neeve style. Trigger on: "write a spec", "spec this",
  "turn this into a work item", "plan this implementation", "write requirements", "convert this bug
  into a spec", "design the fix", "break this into tasks", or any request to transform a problem or
  design direction into structured engineering work. Prioritize the style and decision discipline
  used in `robin-ai/specs/`: clarify the goal first, capture assumptions, state scope and
  boundaries, explain the wiring story end-to-end, make consequences explicit, and derive concrete
  tests from the intended behavior.
---

# To-Spec Skill

This skill writes specs the way Neeve work should be understood by humans before code is written.

The primary style source is `robin-ai/specs/`. That means:

- understand the ask before writing structure
- state what is in scope and out of scope
- explain the owned interfaces and dependency wiring
- make decisions and consequences explicit
- derive tests from the intended behavior
- keep the spec readable enough that a human can reason about the change

The job is not to dump a giant template on the page. The job is to turn ambiguity into a spec a
human can approve, challenge, and implement from.

## Producer Contract

`to-spec` produces the handoff that `implement-spec` consumes.

Every spec written here must make implementation ownership explicit enough that the implementation
skill does not need to guess:

- which task or slice is owned
- which FRs belong to that task or slice
- what is in scope now
- what must not be implemented now
- which invariants must be preserved
- which tests are required before the task is done
- whether the task fits safe implementation size limits

## Core Rules

### Rule 1: Clarify the ask first

Never jump straight to a full spec.

Before writing the spec, first establish:

- what problem is being solved
- whether this is a feature, bug fix, architecture change, or production incident follow-up
- what success looks like
- what is explicitly not being solved

If the ask is ambiguous, stop and clarify before proceeding. If the ask is mostly clear, restate
it crisply and list assumptions before drafting.

### Rule 2: Default to `robin-ai/specs/` style

`robin-ai/specs/` is the primary style guide, not the more generic industry template.

That means specs should usually emphasize:

- summary in plain English
- scope boundaries
- owned interfaces
- end-to-end flow / wiring story
- default decisions and consequences
- build order
- TDD/test derivation
- acceptance criteria that map to observable outcomes

Use heavier metadata and deeper component sections only when the scope genuinely needs them.

### Rule 3: Specs are for humans first

Optimize for comprehension, not ceremony.

- Write prose a reviewer can follow without reverse-engineering the architecture.
- Use tables only when they clarify ownership, contracts, or dependencies.
- Name services, queues, routes, tables, caches, and boundaries concretely.
- Explain why the change is shaped this way, especially when there are non-obvious constraints.

### Rule 4: No scope blur

Every spec must separate:

- owned change
- dependencies
- downstream consumers
- explicit non-goals

If a bug report or ADR could explode into multiple workstreams, the spec must pin down the part
this work item owns and leave the rest out.

### Rule 5: Tests come from intent

The spec must tell humans what proof is required.

- derive tests from use cases, edge cases, and acceptance criteria
- include regression tests for existing behavior that must remain true
- include failure-path tests when the change touches retries, persistence, messaging, authz, or
  external integrations

### Rule 6: Specs must decompose into implementation-sized tasks

The spec should hand off work in slices small enough to implement safely.

Default target:

- new-task implementation: `1-3 files`
- modification-heavy implementation: up to `5 modified files`

If the owned work cannot fit inside those bounds, the spec must split it further before handoff.

## Workflow

Follow this sequence.

### Phase 0 — Goal Clarification

This phase is mandatory.

Before drafting a spec:

1. Classify the ask:
   - feature
   - bug fix
   - architecture / ADR implementation
   - production hardening / incident follow-up
   - refactor with behavioral constraints
2. Restate the goal in plain English.
3. Identify what kind of spec is needed:
   - concise work-item spec
   - full systems spec
4. Identify what is still unclear.

If the ask is underspecified, ask focused clarification questions before proceeding.

Use this shape:

```markdown
## Goal Check

- **Ask type:** [feature / bug / ADR implementation / etc.]
- **What I think the goal is:** [plain-English restatement]
- **What this spec should produce:** [work-item spec or full systems spec]
- **What is still unclear:** [short list or "nothing material"]
```

Do not write the full spec until this phase is done.

### Phase 1 — Context Gathering

Read the best available sources before inventing structure:

- `robin-ai/specs/` first when the style decision is in doubt
- ADRs or design docs
- existing repo docs / README / contracts
- current code structure and reusable components
- bug report or incident details, if this is a fix

Extract:

- existing reusable components
- existing contracts and owned interfaces
- hard constraints
- deployment/runtime assumptions
- blockers and downstream dependents

### Phase 2 — Assumptions Checkpoint

Before the full spec, emit assumptions in human language.

If the context is incomplete or ambiguous, explicitly ask the human to confirm or correct them.
If the context is already solid, still state the assumptions and proceed.

Use this shape:

```markdown
## Assumptions

A1. ...
A2. ...
A3. ...
```

### Phase 3 — Choose the spec shape

Do not force every request into one template. Choose the minimum shape that still makes the change
safe and reviewable.

#### Shape A: Concise work-item spec

Use this for single work items, narrow features, focused bug fixes, or isolated implementation
planning. This should resemble `CBWebhookEnterpriseOrgProvisioning.md`.

Required sections:

1. Title
2. Summary
3. In Scope
4. Out of Scope
5. System Boundaries
6. Owned Interfaces
7. End-to-End Flow
8. Default Decisions
9. Assumptions
10. Reuse Inventory
11. Build Order
12. TDD Order
13. Required Tests
14. Acceptance Criteria
15. Consequences / Follow-on Work
16. Implementation Handoff

#### Shape B: Full systems spec

Use this for cross-service, cross-runtime, or architecture-heavy work. This should resemble
`SPEC-WI-R02-R03.md`.

Required sections:

1. Title
2. Metadata
3. Summary
4. Goals
5. Non-Goals
6. Definitions
7. Assumptions
8. Reuse Inventory
9. Use Cases
10. Functional Requirements
11. Invariants
12. Workflow / Wiring Story
13. Security
14. Interfaces
15. Data Model
16. Edge Cases
17. Non-Functional Requirements
18. Build / Task Order
19. Required Tests
20. Acceptance Criteria
21. Consequences / Follow-on Work
22. Implementation Handoff

### Phase 4 — Write the spec

Write the chosen shape in a way a human reviewer can consume quickly.

Priorities:

- lead with the problem and the owned change
- explain the wiring story in chronological order
- make consequences visible
- avoid fake precision where the source material is still undecided
- distinguish decisions, assumptions, and follow-on work clearly

### Phase 5 — Derive tests

After the spec body is written, derive tests from:

- use cases
- edge cases
- invariants
- acceptance criteria
- regression risk

Load `references/testing.md` when enumerating tests.

## What Good Looks Like

A good Neeve spec lets a human answer all of these:

- What exact problem is being solved?
- What part does this work item own?
- What is out of scope?
- Which services, routes, tables, queues, caches, or clients are involved?
- In what order does the system behave before, during, and after this change?
- What assumptions is the spec making?
- What breaks if an assumption is wrong?
- What tests prove the change is correct?
- What follow-on work still exists after this spec lands?

If the spec cannot answer these cleanly, it is not ready.

## Human-Consumable Writing Rules

- Prefer short paragraphs over giant bullets.
- Use numbered flows when explaining sequence.
- Use tables for ownership, interfaces, assumptions, or reuse inventory.
- Avoid generic headings that do not help the reader reason about the change.
- When writing about a bug fix, explain the prior broken behavior and the corrected behavior.
- When writing about an ADR implementation, explain the consequence of following the ADR in this
  work item.
- When writing about a dependency, name whether it is:
  - authoritative
  - derived
  - cache-only
  - transport-only
  - out of scope

## Reuse-First Rule

Before specifying a new class, service, table, route, worker, or helper, state whether:

- an existing component is reused as-is
- an existing component is extended
- a new component is necessary

If it is new, justify why extension or wiring is insufficient.

Specs that casually create new abstractions without checking the codebase are poor specs.

## Consequence Writing Rule

Every meaningful spec should explain consequences of the change, not just the target behavior.

Examples of consequences to call out:

- rollout constraints
- migration dependencies
- new operational alerts or dashboards
- temporary single-replica or degraded-mode decisions
- what downstream work becomes possible
- what existing work remains blocked

If the change creates a tradeoff, name it.

## Bug-Fix Spec Rule

If the ask is a bug or incident:

- describe the broken current behavior first
- name the invariant or expected behavior being restored
- explain why the bug occurred if known
- specify the regression test that prevents recurrence
- keep speculative refactors out unless they are required for the fix

Do not turn a bug fix into a disguised architecture rewrite without explicit approval.

## Implementation Handoff Rule

Every spec must include a compact handoff block for `implement-spec`.

This handoff must state:

- owned task / slice
- owned FRs
- implement now
- do not implement now
- invariants to preserve
- required tests before done
- runtime / Helm impact
- task sizing or decomposition note

## Output Guidance By Spec Shape

### Concise work-item spec structure

Use this default outline:

```markdown
# [Work Item / Feature Name]

## Summary
[What this work item does and why.]

## In Scope
- ...

## Out of Scope
- ...

## System Boundaries
- ...

## Owned Interfaces
### Input interface
- ...

### Persistence interface
- ...

### Async / downstream interface
- ...

## End-to-End Flow
1. ...
2. ...

## Default Decisions
- ...

## Assumptions
- A1. ...

## Reuse Inventory
| Component | Location | How used |
|---|---|---|

## Build Order
1. ...

## TDD Order
1. ...

## Required Tests
### Unit
- ...

### Integration
- ...

### Regression
- ...

## Acceptance Criteria
- ...

## Consequences / Follow-on Work
- ...

## Implementation Handoff
- **Owned task:** ...
- **Owned FRs:** ...
- **Implement now:** ...
- **Do not implement now:** ...
- **Invariants to preserve:** ...
- **Required tests before done:** ...
- **Runtime / Helm impact:** ...
- **Task sizing:** [fits 1-3 files / up to 5 modified files / requires split]
```

### Full systems spec structure

Use this for multi-component work:

```markdown
# [Spec Title]

## Metadata
- **Status:** Draft
- **Owner:** ...
- **Version:** 0.1
- **Last Updated:** [today]
- **Related ADRs:** ...
- **Related Issues:** ...
- **Blocks:** ...
- **Blocked by:** ...

## Summary
...

## Goals
- ...

## Non-Goals
- ...

## Definitions
| Term | Definition |
|---|---|

## Assumptions
| ID | Assumption | Impact if wrong |
|---|---|---|

## Reuse Inventory
| Component | Location | How used in this spec |
|---|---|---|

## Use Cases
1. ...

## Functional Requirements
### [Component]
- **FR-1.** ...

## Invariants
- **I-1.** ...

## Workflow / Wiring Story
### Write path / Read path / Runtime flow
1. ...

## Security
...

## Interfaces
### Events / HTTP / etc.
...

## Data Model
...

## Edge Cases
- ...

## Non-Functional Requirements
- **Performance:** ...
- **Reliability:** ...
- **Observability:** ...

## Build / Task Order
1. ...

## Required Tests
| Use Case | Test ID | Type | What it verifies |
|---|---|---|---|

## Acceptance Criteria
- ...

## Consequences / Follow-on Work
- ...

## Implementation Handoff
- **Owned task or slice:** ...
- **Owned FRs:** ...
- **Implement now:** ...
- **Do not implement now:** ...
- **Invariants to preserve:** ...
- **Required tests before done:** ...
- **Runtime / Helm impact:** ...
- **Task sizing / decomposition note:** ...
```

## Quality Rules

Apply throughout the spec:

- keep work-item tasks independently reviewable
- specify quality gates only when they are useful and repo-appropriate
- do not overfit every spec to micro-tasks if the human first needs the architecture clarified
- preserve DDD / Protocol / contract-first patterns when they match the repo
- load `references/ddd-patterns.md` for domain-heavy work
- load `references/frontend.md` for UI/BFF work
- load `references/security-checklist.md` for the security section
- load `references/testing.md` for test derivation and coverage expectations

## Anti-Patterns

Do not:

- blurt out a full spec without clarifying the goal
- write generic template filler with no repo grounding
- create a huge task list before explaining the system story
- mix owned work with downstream or speculative work
- hide assumptions
- omit regression tests for bug fixes or production incidents
- force every request into the heaviest possible spec format

## Reference Files

Load on demand:

| File | When to load |
|------|-------------|
| `references/testing.md` | When deriving tests and coverage expectations |
| `references/frontend.md` | When the spec touches frontend, BFF, or browser behavior |
| `references/ddd-patterns.md` | When the spec touches aggregates, repositories, or layered architecture |
| `references/security-checklist.md` | Always when writing security-sensitive specs |
