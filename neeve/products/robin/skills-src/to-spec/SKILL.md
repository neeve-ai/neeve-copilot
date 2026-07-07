---
name: to-spec
description: >
  Turn an ADR, feature request, bug report, incident, rough idea, or implementation note into a
  human-consumable engineering spec in the Neeve style. Trigger on: "write a spec", "spec this",
  "turn this into a work item", "plan this implementation", "write requirements", "convert this bug
  into a spec", "design the fix", "break this into tasks", or any request to transform a problem or
  design direction into structured engineering work. Prioritize the style and decision discipline
  used in `specs/`: clarify the goal first, capture assumptions, state scope and
  boundaries, explain the wiring story end-to-end, make consequences explicit, and derive concrete
  tests from the intended behavior.
---

# To-Spec Skill

This skill writes specs the way Neeve work should be understood by humans before code is written.

The primary style source is `specs/`. That means:

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

### Rule 2: Default to `specs/` style

`specs/` is the primary style guide, not the more generic industry template.

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
- every AC must map to at least one named test: a unit test name or an `IT-N` integration test identifier
- every test case listed in Required Tests must carry a `# spec: AC-xx` annotation instruction so the CI coverage script can enforce traceability

### Rule 7: ACs must be in Given/When/Then form

Every acceptance criterion must be binary and testable.

Required format:
```
AC-01: Given [precondition] When [action] Then [observable outcome]
```

Rules:
- Never write ACs as prose assertions ("The system writes a row") — these will be rejected as 🔴 Critical by the spec reviewer.
- ACs must be binary: the test either passes or fails, with no ambiguity.
- IDs must be sequential: `AC-01`, `AC-02`, `AC-03`, …
- Retired ACs must be struck through (`~~AC-05~~ (removed: reason)`), never silently deleted.
- Every AC must map to a named test in the Required Tests section.

### Rule 8: Specs must satisfy the 8 spec-review checks before handoff

#### Check 1 — Scope Accuracy
Map every acceptance criterion to the source of truth (e.g., FR text, bug report, ADR section). If any AC cannot be traced to a specific claim in the source material, either delete it or move it to a named future work item. If the source material is ambiguous, clarify it before writing the ACs. Do not add ACs that have no basis in the source of truth.

#### Check 2 — Scope Bleed
Every FR, NFR, DoD item, and metric must be traceable to the source of truth. Do not add:
- Prometheus metrics the work item does not mention
- performance baselines the work item does not require
- routes or behavior owned by a different named work item

For each addition beyond the source of truth, decide: delete it or move it to a named future work item.

#### Check 3 — Reuse First
Before specifying a new pattern, read the relevant files in the codebase and ask:
- Is there an existing component I can reuse as-is?
- Is there an existing component I can extend?
- Do I really need a new component, or can I wire the existing ones together in a new way?

#### Check 4 — Integration Test as AC
Every AC must map to either a unit test or a named `IT-N` integration test. Check:
- No unmapped ACs.
- Mock session lists in each IT-N are consistent with the FR logic (the COUNT path runs only on no-match; do not include a COUNT session in a group-match IT).
- No AC or DoD item says "test DB" or "real Postgres" when the repo pattern is mocked sessions.

#### Check 5 — AC Robustness
For every FR, the Required Tests and Acceptance Criteria together must cover:
- [ ] Happy path
- [ ] Concurrent access (same-user race, two-replica race)
- [ ] Infrastructure failure (Redis unavailable, DB connection error)
- [ ] Missing/null inputs (`groups=None`, `org_id=""`, absent optional fields)
- [ ] Idempotency (second request sees sentinel / provisioning blocked)
- [ ] Incorrect data (invalid role, mismatched constraint)
- [ ] Pre-existing state (already provisioned by another path)
- [ ] Re-raise vs. swallow (race → catch and continue; data bug → re-raise)

A concurrency or idempotency path named in FR text but absent from ACs is a 🔴. A negative path in Edge Cases with no AC or test is a 🟡.

#### Check 6 — Technical Accuracy
Before finalising the spec:
- Every file listed in File / Module Impact either exists or is marked `NEW`.
- Every field name in Data Model tables and IT-N assertions matches the ORM column name in the model file.
- Exception class names must exist in SQLAlchemy (`sqlalchemy.exc.IntegrityError`, not `UniqueConstraintViolationError`).
- Python truth-value claims must be correct (`bool(" ") == True` — whitespace strings are truthy).
- Pydantic version: if the model uses `class Config` it is v1; `model_config` dict is v2.
- NFR SELECT counts must match the actual number of `get_session()` calls through the FR sequence.
- Redis key patterns must match how existing code writes them.

#### Check 7 — Cross-Repo and Cross-Spec Citations
- When citing "ADR-NNNN §Section", verify the section heading exists in the ADR file.
- When citing "WI-XXX owns …", verify the claim in the work item text or ACs.
- When referencing another spec section, verify the heading exists.

#### Check 8 — Template Compliance
Before handoff, verify the spec satisfies all structural requirements:

| Requirement | Rule |
|---|---|
| AC format | Every AC is `Given … When … Then …` (binary) |
| AC IDs | Sequential, no silent gaps; retired IDs struck through |
| `# spec: AC-xx` annotations | Every test in Required Tests carries an annotation instruction |
| Named CHECK constraints | Every DB constraint has an explicit `name="ck_…"` |
| Bounded context | Metadata or Definitions identifies the owning domain (`auth`, `task`, `membership`, …) |
| Type aliases | `NewType` aliases named for typed identifiers (OrgId, UserUuid, …) |
| Definition of Done | Must include: ≥ 95% line + branch coverage · zero `mypy --strict` errors · every AC has ≥ 1 annotated test · named constraints · observability metrics |
| CONTEXT.md alignment | New domain terms introduced in Definitions should appear in `CONTEXT.md` |

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

- reachable examples in `specs/` first when the style decision is in doubt
- ADRs or design docs
- existing repo docs / README / contracts
- current code structure and reusable components
- bug report or incident details, if this is a fix
- **this repo's `context-src/repos/<repo>.yaml` in `neeve-copilot`, if this
  repo is registered there** — cite its `do_not_modify` list, `stack`, and
  `spec_based_development` flag the same way `repo-guide` would. This is
  mandatory, not optional: don't let this step depend on whether the person
  driving remembered to ask `repo-guide` first — a spec that proposes
  touching something on the do-not-modify list must call that out
  explicitly here, regardless of who's writing it.

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

Do not force every request into one template. Choose the minimum shape that still makes the change safe and reviewable. If a strong existing multi-component spec (for example, `specs/SPEC-*.md`) is accessible, use it to ground the template and style decision. If not found, default to the concise work-item spec structure given below.

Required sections (must appear in this order):
1. Title
2. Goal Check
3. Summary
4. In Scope
5. Out of Scope
6. System Boundaries
7. Owned Interfaces
8. Functional Requirements
9. End-to-End Flow
10. Default Decisions
11. Assumptions
12. Reuse Inventory
13. Security
14. Build Order
15. TDD Order
16. Required Tests (with FR-to-test mapping subsection)
17. Acceptance Criteria
18. Definition of Done
19. Consequences / Follow-on Work
20. Implementation Handoff

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

For each FR, verify the Required Tests section covers all 8 robustness paths from Rule 8 Check 5
(happy path, concurrent access, infrastructure failure, null inputs, idempotency, incorrect data,
pre-existing state, re-raise vs. swallow). A FR with fewer than the applicable paths is incomplete.

### Phase 6 — Spec Review Self-Check

This phase is mandatory before writing the Implementation Handoff block.

Run all 8 checks from Rule 8 on the draft spec and emit a compact self-review **in your response** (not in the spec file):

```
## Spec Self-Review (pre-handoff)

| Check | Status | Notes |
|---|---|---|
| 1 Scope Accuracy | ✅ / ⚠️ | [any gap] |
| 2 Scope Bleed | ✅ / ⚠️ | [any addition beyond source of truth] |
| 3 Reuse First | ✅ / ⚠️ | [any pattern mismatch] |
| 4 Integration Test as AC | ✅ / ⚠️ | [any unmapped AC] |
| 5 AC Robustness | ✅ / ⚠️ | [any missing path] |
| 6 Technical Accuracy | ✅ / ⚠️ | [any wrong field/exception/count] |
| 7 Cross-Repo Citations | ✅ / ⚠️ | [any unverified citation] |
| 8 Template Compliance | ✅ / ⚠️ | [any missing structural element] |
```

Do not write the Implementation Handoff block until every check is ✅ or any ⚠️ items are
explicitly resolved or deferred with a note.

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

Before writing this block, verify all of the following:

- every assumption is confirmed or explicitly marked unverified
- every owned FR maps to at least one required test
- task sizing has been assessed

If any of these checks fail, do not write the handoff block yet. Resolve the ambiguity, mark the
assumption status explicitly, add the missing test mapping, or split the task further before
handoff. Do not pass hidden gaps to `implement-spec`.

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

Use this default outline. Headings are canonical — do not rename, reorder, or omit them.

```markdown
# [WI-XXX: Work Item / Feature Name]

## Goal Check

- **Ask type:** [feature / bug / ADR implementation / etc.]
- **What I think the goal is:** [plain-English restatement]
- **What this spec should produce:** [work-item spec or full systems spec]
- **What is still unclear:** [short list or "nothing material"]

## Summary
[What this work item does and why.]

## In Scope
- ...

## Out of Scope
- ...

## System Boundaries
- **[Role]:** [what this system/dependency owns]
- ...

## Owned Interfaces

### Input interface
- ...

### External API interface
- ...

### Configuration interface
- ...

### Dependency wiring interface
- ...

## Functional Requirements

- **FR-1.** ...
- **FR-2.** ...

## End-to-End Flow

1. ...
2. ...

## Default Decisions

- ...

## Assumptions

- **A1.** ...

## Reuse Inventory

| Component | Location | How used |
|---|---|---|

## Security

### Fail-closed model
- ...

### Authentication and authorization
- ...

### PII handling
- ...

### Secret management
- ...

### Input validation surface
- ...

### Audit trail
- ...

### Production consequence if this is wrong
- **Blast radius:** [one request / one session / one tenant / cross-tenant / platform-wide]
- **Who notices:** [operator / end customer / on-call / no one]
- **Rollback / kill-switch:** [feature flag, revertable migration, config toggle — or "revert the deploy" if nothing faster exists]

## Build Order

1. **Slice 1 (...):**
   - ...
2. **Slice 2 (...):**
   - ...

## TDD Order

1. ...

## Required Tests

### Unit
- **T-01:** ...

### Integration
- **T-N:** ...

### Regression
- **T-N:** ...

### FR-to-test mapping

| FR | Tests |
|---|---|
| FR-1 | T-N, T-N |

## Acceptance Criteria

<!-- Every AC must be: Given [precondition] When [action] Then [observable outcome] -->
<!-- IDs must be sequential (AC-01, AC-02, …). Retired IDs: ~~AC-N~~ (removed: reason) -->
- AC-01: Given … When … Then …

## Definition of Done

- [ ] ≥ 95% line + branch coverage
- [ ] Zero `mypy --strict` errors
- [ ] Every AC has ≥ 1 annotated test (`# spec: AC-xx`)
- [ ] All DB constraints use explicit `name="ck_…"` syntax
- [ ] Observability metrics specified (or N/A with justification)
- [ ] Production consequence and gaps stated below — not left blank

## Consequences / Follow-on Work

- **Production consequence:** [what breaks/degrades, what's exposed, blast radius, rollback story — see Security § Production consequence above]
- **Gaps / residual risk:** [named gap — missing security control, untested path, missing CI gate — or "none identified, verified via [what was checked]"]
- ...

<!-- Handoff gate:
     1. Run all 8 spec-review checks (Rule 8) and emit Spec Self-Review table in your response (not in the file).
     2. Confirm or explicitly mark assumption status.
     3. Map each owned FR to at least one required test.
     4. Assess task sizing.
     Do not write the Implementation Handoff block until all 8 checks are ✅ or deferred with a note. -->

## Implementation Handoff

- **Owned task:** ...
- **Owned FRs:** ...
- **Implement now:**
  - ...
- **Do not implement now:**
  - ...
- **Invariants to preserve:**
  - ...
- **Required tests before done:** T-01 through T-N.
- **Runtime / Helm impact:** ...
- **Task sizing / decomposition note:** [fits 1-3 files / up to 5 modified files / requires split]
```

### Full systems spec structure

Use this for multi-component work. When reachable, an existing production-grade multi-component spec in `specs/` should be used as the anchor example for how these sections should read in practice:

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

### Production consequence if this is wrong
- **Blast radius:** [one request / one session / one tenant / cross-tenant / platform-wide]
- **Who notices:** [operator / end customer / on-call / no one]
- **Rollback / kill-switch:** [feature flag, revertable migration, config toggle — or "revert the deploy" if nothing faster exists]

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
<!-- Every AC must be: Given [precondition] When [action] Then [observable outcome] -->
<!-- IDs must be sequential (AC-01, AC-02, …). Retired IDs: ~~AC-N~~ (removed: reason) -->
- AC-01: Given … When … Then …

## Definition of Done
- [ ] ≥ 95% line + branch coverage
- [ ] Zero `mypy --strict` errors
- [ ] Every AC has ≥ 1 annotated test (`# spec: AC-xx`)
- [ ] All DB constraints use explicit `name="ck_…"` syntax
- [ ] Observability metrics specified (or N/A with justification)
- [ ] Production consequence and gaps stated below — not left blank

## Consequences / Follow-on Work
- **Production consequence:** [what breaks/degrades, what's exposed, blast radius, rollback story — see Security § Production consequence above]
- **Gaps / residual risk:** [named gap — missing security control, untested path, missing CI gate — or "none identified, verified via [what was checked]"]
- ...

<!-- Handoff gate:
     1. Run all 8 spec-review checks (Rule 8) and emit Spec Self-Review table.
     2. Confirm or explicitly mark assumption status.
     3. Map each owned FR to at least one required test.
     4. Assess task sizing.
     Do not write the block until all 8 checks are ✅ or deferred with a note. -->

<!-- Spec Self-Review: emit this table in your response before writing the Implementation Handoff block — do NOT include it in the spec file.

| Check | Status | Notes |
|---|---|---|
| 1 Scope Accuracy | ✅ / ⚠️ | |
| 2 Scope Bleed | ✅ / ⚠️ | |
| 3 Reuse First | ✅ / ⚠️ | |
| 4 Integration Test as AC | ✅ / ⚠️ | |
| 5 AC Robustness | ✅ / ⚠️ | |
| 6 Technical Accuracy | ✅ / ⚠️ | |
| 7 Cross-Repo Citations | ✅ / ⚠️ | |
| 8 Template Compliance | ✅ / ⚠️ | |
-->

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
- write ACs as prose assertions — every AC must be `Given … When … Then …`
- silently delete an AC ID — retire it with `~~AC-N~~ (removed: reason)`
- add Prometheus metrics, performance baselines, or DoD items that have no basis in the source of truth (scope bleed)
- invent new error-handling patterns when `IntegrityError`, `MagicMock`, or session patterns already exist in the codebase
- say "test DB" or "real Postgres" when the repo uses mocked sessions
- introduce a new library or global singleton the codebase does not already use
- omit the bounded context or type aliases from the template sections
- write the Implementation Handoff block before the Spec Self-Review table is completed

## Reference Files

Load on demand:

| File | When to load |
|------|-------------|
| `references/testing.md` | When deriving tests and coverage expectations |
| `references/frontend.md` | When the spec touches frontend, BFF, or browser behavior |
| `references/ddd-patterns.md` | When the spec touches aggregates, repositories, or layered architecture |
| `references/security-checklist.md` | Always when writing security-sensitive specs |
| `references/quality-gates.md` | When writing Definition of Done and Required Tests — ensures all 7 gates are specced |

---

## Skill Chain

`to-spec` turns a problem into a structured, reviewable spec. It sits between context
gathering and implementation. Never write a spec without first understanding the codebase.

| Situation | Prior skill to run first |
|---|---|
| Codebase is unfamiliar — need to understand existing patterns before speccing | → run `repo-ask` first |
| Need a full picture of a service before speccing a change to it | → run `repo-intel` first |
| Spec involves a UI/DLS surface | → consult `neeve-dls` for component/token context first |

| Situation | Next skill after spec is approved |
|---|---|
| Spec is approved and ready to build | → `implement-spec` |
| Spec reveals a security concern requiring dedicated review | → `code-review` with security focus after implementation |

**Feeds into:** `implement-spec`, `code-review`
**Fed by:** `repo-ask`, `repo-intel`

The spec's Definition of Done must reference all 7 gates in `references/quality-gates.md`.
The spec is not approvable if any gate is absent without a written justification.
