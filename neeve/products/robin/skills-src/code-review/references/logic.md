# Logic Review Reference

This file is for **analytical PR review**, not generic bug-spotting.

The reviewer must evaluate logic as a **change against a parent branch baseline**. The question is
not "does this code seem reasonable in isolation?" The question is:

`What behavior changed relative to the parent branch, what behavior was intended by the spec, and did the PR improve the system without introducing regression or additive junk?`

Use this reference whenever reviewing changed logic, workflow behavior, state transitions, retries,
authorization, eventing, caching, migrations, or business rules.

## 1. Differential Logic Review Protocol

Run this sequence in order.

### Step 1: Establish the baseline

Identify the parent branch or merge base, then determine:

- what the old behavior was
- what invariants the old code preserved
- what tests or contracts previously defined as correct

Do not skip this. A logic review without a baseline becomes opinion.

### Step 2: Locate the intended change

Read the strongest intent source available:

- ADR
- spec in `specs/`
- OpenAPI / contract doc
- acceptance criteria / work item
- test plan or release note when no formal spec exists

Extract the intended delta in plain language:

- what new behavior is expected
- what old behavior must remain unchanged
- what is explicitly out of scope

### Step 3: Map changed code to intended change

For each changed file or function, ask:

- which requirement or acceptance criterion does this implement?
- which old behavior is being replaced, extended, or removed?
- is this change necessary to satisfy the spec?
- what downstream callers, events, DB rows, cache keys, contracts, or Helm values now behave
  differently?

If code cannot be mapped to intent, treat it as suspicious until proven necessary.

### Step 4: Evaluate regressions

Compare the changed behavior to parent-branch behavior and find:

- broken invariants
- degraded guarantees
- new failure modes
- changed edge-case behavior
- hidden compatibility breaks

### Step 5: Evaluate additive code

Reject additive code that does not materially advance the owned change.

Examples:

- new helper/service/module that just wraps existing behavior with no semantic gain
- extra flags, branches, DTO fields, config, or abstractions not required by the spec
- parallel logic path introduced instead of replacing obsolete behavior
- dead "future proofing" code with no current caller or acceptance criterion

If the PR solves the target problem by layering more code on top of old behavior instead of
clarifying or replacing it, that is a real review concern.

## 2. Review Output Model

Every logic finding should answer four things:

1. **What changed relative to parent branch?**
2. **What did the spec or existing invariant require?**
3. **Why is the new behavior invalid, risky, or unnecessary?**
4. **What should happen instead?**

If a finding cannot explain the before/after behavior, it is probably too weak.

## 3. Regression Analysis Checklist

Use this checklist on every non-trivial PR.

### Behavior preservation

Check whether the PR accidentally changed:

- default behavior
- error handling
- empty-input behavior
- retry or replay behavior
- ordering guarantees
- logging/audit side effects
- authz decisions
- tenant scoping
- serialization / response shape
- cache invalidation behavior
- background-task lifecycle

### Invariant preservation

Ask whether the parent branch guaranteed any of these and the PR weakens them:

- single-write semantics
- idempotency under retries
- transaction atomicity
- publish-after-commit ordering
- fail-closed behavior
- backward-compatible contracts
- deterministic selection/derivation behavior
- one source of truth for a given field or decision

### Compatibility preservation

Ask whether the PR silently breaks:

- callers
- stored data assumptions
- migrations
- existing tests that encoded intended behavior
- OpenAPI / contract consumers
- env/config expectations in Helm

## 4. Spec-Intent Validation

For each meaningful logic change, classify the result:

- **Valid implementation**
  - the change is required by the spec
  - the implementation preserves existing non-target behavior
  - tests prove the intended delta
- **Partial implementation**
  - some spec behavior landed, but the PR misses an important branch or acceptance criterion
- **Regression**
  - the PR breaks behavior that should have remained true
- **Scope creep**
  - the PR adds behavior not justified by the spec
- **Additive code slurp**
  - the PR adds code volume, branches, or abstractions without clarifying ownership or reducing risk

### Additive code slurp heuristics

Flag the PR when it does one or more of these:

- adds a second code path without deleting the obsolete one
- adds configuration for behavior that has only one supported mode
- introduces wrappers/factories/DTOs with no contract or testing benefit
- adds "future" branches guarded by comments instead of accepted scope
- duplicates validation or transformation logic instead of consolidating it
- keeps old state writes/events and adds new ones on top, producing ambiguity

The burden of proof is on the PR author: extra code must buy a concrete guarantee, compatibility
bridge, or contract boundary.

## 5. Differential Failure Modes To Check

These are the high-value logic regressions that often appear in PRs.

### A. State transition regression

Parent branch had a clear transition model; PR introduces illegal or unhandled transitions.

Look for:

- missing guards before state mutation
- skipped intermediate state required by downstream systems
- new terminal state with no consumers/tests
- state written in two places with no ordering rule

### B. Replay and idempotency regression

Parent branch tolerated duplicate delivery or retried commands; PR now duplicates side effects.

Look for:

- insert-always replacing lookup-or-reuse
- event publish retried without dedupe
- external charge/email/provisioning call issued before durable write
- request keys or dedupe keys changed incompatibly

### C. Ordering regression

PR changes sequencing so downstream systems can observe inconsistent truth.

Look for:

- publish before commit
- cache invalidation before source-of-truth update
- DB write after irreversible external side effect
- async/background handoff before durable persistence

### D. Tenant-boundary regression

PR preserves functional behavior for one tenant but weakens isolation.

Look for:

- removed `organization_id` filters
- cache keys no longer scoped by tenant
- resource lookup by raw ID without ownership check
- response payload now exposing cross-tenant data

### E. Contract regression

Implementation changes behavior without updating the consumer contract.

Look for:

- response field added/renamed/removed
- semantics changed while field names stayed the same
- event payload shape drift
- route accepts/returns values that the versioned contract does not declare

### F. Fallback regression

PR adds a fallback that makes the system look resilient but actually weakens guarantees.

Look for:

- swallowing dependency errors and returning empty/success
- permissive defaulting on authz or config errors
- silent `None` / empty list fallback that changes business meaning
- cache miss handling that returns guessed data instead of authoritative data

## 6. Analytical Questions For Common Change Types

### Domain derivation / parsing changes

Ask:

- what did the old parser/deriver accept or reject?
- what new inputs now pass or fail?
- is the derivation stable and deterministic?
- is the output used as a durable key, display field, slug source, or cache key?
- does the spec distinguish raw value vs normalized value vs registered/canonical value?

Typical regressions:

- changing canonicalization rules without migration or replay consideration
- collapsing two semantically distinct fields into one derived value
- widening acceptance in a way that admits invalid durable identifiers

### API / handler logic changes

Ask:

- did the response code/body semantics change?
- did failure behavior change from explicit error to silent ignore?
- did request validation move later in the flow?
- are side effects now triggered for requests previously treated as no-op?

### Worker / event logic changes

Ask:

- what is the durable handoff boundary?
- what happens on crash between state write and event publish?
- can the same message be processed twice?
- did the PR weaken ordering or singleton assumptions?

### Persistence / migration logic changes

Ask:

- can old rows still be read correctly?
- can mixed-version app instances coexist during rollout?
- did the PR change uniqueness, nullability, or durable key semantics?
- are backfill assumptions explicit and tested?

## 7. Evidence Standards

A logic change is not well-reviewed until the evidence covers the delta.

### Required evidence for strong confidence

- tests proving the intended new behavior
- tests preserving the old invariant that must remain true
- explicit coverage of the failure or replay path if the change touches retries, events, payments,
  authz, provisioning, or persistence
- contract updates when boundary behavior changed

### Weak evidence patterns

Treat these as insufficient:

- only snapshot updates
- only happy-path unit tests
- tests that assert helpers were called but not that the observable behavior is correct
- new abstractions with no test proving why they need to exist
- "manual testing" claim with no codified regression proof

## 8. Example Finding Shapes

### Regression finding

```text
[HIGH] Replay regression in provisioning job creation
Parent branch behavior: duplicate webhook deliveries reused the existing durable job identity.
Spec intent: webhook ingestion must be idempotent and return 200 after durable handoff.
PR behavior: the new path inserts before checking for an existing job, so duplicate deliveries can
create multiple jobs and publish multiple handoff events.
Why this is invalid: the PR breaks an existing invariant on a retry-prone integration path.
Fix: restore lookup-or-create semantics and add a duplicate-delivery regression test.
```

### Additive code finding

```text
[MEDIUM] Additive branch introduces unsupported alternate path
Parent branch behavior: one derivation path produced the durable domain key.
Spec intent: derive raw and registered domain values for provisioning; no optional mode exists.
PR behavior: introduces a feature-flagged fallback derivation path and extra helper class with no
acceptance criterion, no caller need, and no compatibility bridge.
Why this is invalid: the PR increases code surface and ambiguity without advancing the owned change.
Fix: remove the alternate path and keep a single tested derivation flow.
```

## 9. Review Principle

Logic review should feel like controlled diff analysis, not creative writing.

Anchor every conclusion to:

- parent-branch behavior
- spec or invariant intent
- observable delta
- regression or necessity

If you cannot explain why the new logic is better than the old logic for the stated scope, the PR
has not earned the added code.
