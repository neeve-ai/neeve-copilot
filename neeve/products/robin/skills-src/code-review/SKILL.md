---
name: code-review
description: >
  Deep, evidence-based production code review for Neeve-style services, APIs, workers, frontends,
  libraries, and Helm/Kubernetes changes. Trigger on: "review this code", "review this PR",
  "code review", "audit these changes", "is this production-ready", "release readiness", "check
  my PR", "review my charts", "review my Helm changes", "review my design/implementation", or any
  request to assess correctness, safety, contracts, architecture, or deployability. Use this skill
  for snippets and whole repositories. Prioritize ADR/spec alignment, contract fidelity, tenant and
  security safety, idempotency, observability, CI quality gates, and Helm/Kubernetes production
  behavior.
---

# Code Review Skill

This skill performs review the way Neeve systems are actually built and shipped:

`ADR -> spec/contract -> implementation -> tests -> Helm/Kubernetes deploy -> release`

The job is not to produce a generic style audit. The job is to detect anything that would break
correctness, violate design intent, create operational surprise, or disturb production.

## Review Posture

- Review against the repository's stated design, not your preferred design.
- Be strict on behavior, contracts, data safety, security, and deployability.
- Be quiet on nits unless they materially improve maintainability.
- Every finding must explain the production or delivery impact.
- Do not invent a finding when the code is merely different from how you would write it.
- Optimize for human consumption: fewer, stronger findings beat exhaustive noise.

## SMART Review Policy

The layered review model is for analysis depth, not comment volume. Use it to think broadly, then
emit only what a human should act on.

Every surfaced finding should be `SMART`:

- `Specific`: tied to a concrete diff, invariant, contract, or deployment behavior
- `Material`: meaningful to correctness, safety, operability, maintainability, or delivery risk
- `Actionable`: the owner can fix it without guessing what you mean
- `Rooted`: anchored in spec, baseline behavior, or a production invariant, not personal style
- `Triageable`: important enough to consume scarce review attention

If a point fails one or more of these tests, suppress it or fold it into a bucket.

## Review Economy

Default to a concise, senior-review output.

- Prefer `3-7` primary findings.
- Only exceed `7` when there are genuinely multiple independent defects that each require attention.
- Do not emit the same root problem through multiple layers. Consolidate it once at the highest
  signal framing.
- Prefer root-cause findings over symptom findings.
- Prefer one finding with 3 consequences over 3 separate findings describing the same defect.
- Suppress style, naming, and micro-cleanup commentary unless it blocks safe evolution or hides a
  real defect.

When there are many secondary issues:

- emit the most important fix-worthy findings individually
- summarize the rest as bucketed follow-up themes
- make clear which buckets are optional follow-up vs merge-blocking

## Required Discovery

Before reviewing, gather enough context to understand the change in-system.

1. Read the changed files and the nearest surrounding code.
2. Read the strongest design sources that exist for that area:
  - ADRs in `adr/`, `architecture/`, or repo-local design docs
   - `specs/`, `docs/contracts/`, `openapi.yaml`, or feature docs
   - `README*`, `docs/`, `AGENTS.md`, `CLAUDE.md`, release/testing guides
   - Helm chart docs and values when runtime behavior is affected
3. Read the relevant tests, not just implementation.
4. Classify the change. Most Neeve changes fall into one or more of:
   - backend/API service
   - event-driven worker or NATS flow
   - data model or migration
   - frontend/BFF or contract client
   - shared library / interface layer
   - Helm/Kubernetes deployment

Do not review a fragment in isolation when you can inspect the spec, callers, tests, or deployment
surface.

## Neeve Review Ladder

Run the review in this order. Do not skip steps.

### Gate 0: Delivery Trail

Verify the change has the right level of design trail.

- Architecture or cross-service behavior change:
  - expect an ADR, or a clearly equivalent design record
- Feature or behavior change:
  - expect a spec, contract, acceptance criteria, or strong feature doc
- Interface change:
  - expect an OpenAPI/schema/typed contract update
- Deployment behavior change:
  - expect Helm/config/docs changes where appropriate

If a design trail exists, verify the implementation still matches it:

- check that the implemented scope stays within the accepted work item/spec
- check that stated acceptance criteria are satisfied by the implementation and its tests

Flag the absence of design trail when it blocks safe review:

- `HIGH`: behavior changed across service boundaries, authz, billing, data model, or deployment with
  no spec/ADR trail
- `MEDIUM`: local behavior changed and intent must be inferred from tests/code only

Flag spec-fidelity failures here, not later:

- `HIGH`: implementation scope exceeds the accepted spec or work item
- `HIGH`: spec exists but the implementation does not satisfy stated acceptance criteria

### Gate 1: Contract And Architecture Integrity

Load `references/spec.md` and `references/principles.md`.

Check that the implementation respects Neeve architecture patterns:

- contract-first boundaries
- Protocol/interface-driven design
- explicit Pydantic/OpenAPI/data contracts
- dependency injection over hidden singletons
- clean layer boundaries
- no scope creep beyond the stated work item or spec

Escalate when code outruns accepted design. In Neeve repos, "working code" is not enough if it
breaks the ADR/spec chain.

### Gate 2: Correctness, Data Safety, And Multi-Tenancy

Load `references/logic.md`, `references/smells.md`, and `references/principles.md`.

Focus on the failure modes that matter in Neeve systems:

- compare the PR against the parent-branch baseline, not just the new code in isolation
- identify the intended behavior delta from the spec or accepted invariant
- incorrect domain logic
- regression against previously correct behavior
- broken idempotency or replay handling
- outbox/event ordering mistakes
- transaction boundaries that leak partial state
- tenant isolation gaps (`organization_id`, ownership, scoping)
- contract drift between producer and consumer
- cache invalidation or stale-data hazards
- migration safety and backward compatibility gaps
- additive code that increases branches, wrappers, or helpers without advancing the owned change

When a change touches persistence, events, or authz, assume the blast radius is high until proven
otherwise.

### Gate 3: Runtime Resilience, Security, And Operability

Load `references/security.md`, `references/kubernetes.md`, and `references/principles.md`.

Check:

- timeout/retry behavior on external calls
- fail-closed behavior where required
- structured logging and traceability
- metrics on critical paths
- secrets handling
- authn/authz correctness
- graceful shutdown and readiness behavior
- NATS / Redis / DB failure handling
- concurrency and background-task lifecycle

Neeve services are not allowed to be "correct only when dependencies are healthy."

### Gate 4: Evidence And Quality Gates

Load `references/typing.md` and `references/principles.md`.

Check that the change is backed by proof:

- tests cover the changed behavior, not just happy paths
- edge cases and failure paths are exercised
- types are complete and strictness is preserved
- lint/type/coverage expectations remain realistic
- contract tests are updated when interfaces move
- release/deploy notes exist when operational behavior changed

Missing tests are a real finding when the change modifies business behavior, contracts, deployment,
or failure handling.

### Gate 5: Helm/Kubernetes Production Readiness

Always run this gate for services deployed through Helm charts or any manifest/chart change.

Check:

- chart source and packaged subchart implications are understood
- values structure matches repo conventions
- probes, resources, rollout strategy, PDB, monitoring, and security context are sane
- env-specific overrides do not introduce drift or hidden prod-only behavior
- app changes and chart/env changes are consistent with each other

If code requires new env vars, health endpoints, ports, metrics, secrets, or sidecars, the review
must verify the Helm layer too.

## Severity Model

Use these tiers exactly:

- `CRITICAL`: exploitable security issue, data corruption/loss, broken tenant boundary, broken authz,
  irreversible deploy hazard, crash-loop/liveness failure, or guaranteed production outage
- `HIGH`: spec/ADR violation, missing transactional or idempotency guarantee, broken contract,
  false-confidence tests, unsafe migration, serious resilience gap
- `MEDIUM`: maintainability or correctness risk that is not immediately fatal, missing design trail
  for a local change, notable observability/test gap
- `LOW`: small improvement or nit. Cap at 5.

## Finding Selection Rules

Before emitting a finding, ask:

1. Does this require a code/config/spec/test change, or just personal preference?
2. Will this matter in production, rollout, future maintenance, or contract safety?
3. Is this independent from the other findings, or just another face of the same problem?
4. Would I want this called out if I were the PR owner with limited attention?

Emit only if the answer pattern justifies human attention.

### Always surface individually

- production-breaking or security-relevant defects
- regressions against spec, baseline behavior, or tenant/authz guarantees
- unsafe migrations, ordering bugs, idempotency failures, fail-open behavior
- missing tests when they leave high-risk behavior unproven
- Helm/config drift that makes the change unsafe or undeployable

### Usually bucket instead of emitting individually

- repeated instances of the same smell across multiple files
- a cluster of low/medium test gaps with one shared root cause
- multiple naming/cleanup issues in the same module
- several contract or typing papercuts caused by one broader refactor
- stylistic inconsistency with no operational effect

### Usually suppress

- purely stylistic alternatives
- speculative future-proofing opinions unless the current code is harmful
- tiny local cleanups unrelated to the changed behavior
- duplicate observations already covered by a stronger finding

## Neeve-Specific Review Rules

### Process Rules

- Treat ADRs and specs as enforcement artifacts, not optional reading.
- For work-item-driven changes, verify the implementation matches the stated scope and acceptance
  criteria.
- Flag "while I was here" additions that were not pulled into the spec.

### Backend And Worker Rules

- Prefer Protocols and explicit contracts over concrete coupling.
- Check publish-after-commit ordering on event-driven flows.
- Check idempotency on webhook, billing, provisioning, and retryable workflows.
- Check fail-closed semantics for authorization and safety-critical paths.
- Check background workers for singleton assumptions, shutdown behavior, and retry semantics.

### Frontend / BFF Rules

- Verify contract versioning and API client behavior against OpenAPI/docs.
- Ensure UI changes do not silently depend on backend fields not in contract.
- Treat release and backport considerations as part of review when versioned flows change.

### Helm Rules

- Security defaults matter: non-root, least privilege, secrets via references, not literals.
- Production services need probes, resources, metrics, and sane rollout controls.
- Watch for hidden chart drift between source templates, packaged charts, and env override files.

## Output Format

Start with findings. Findings are the product.

```markdown
## Findings

1. [HIGH] Missing idempotency guard on provisioning replay
  - File: `services/auth/handler.py:88`
   - Why it matters: duplicate webhook delivery can create multiple jobs and divergent downstream state.
   - Evidence: spec requires durable idempotent reuse, but the implementation always inserts.
   - Fix: enforce lookup-or-create on the durable key and add a replay test.

2. [MEDIUM] Contract drift between response model and OpenAPI
  - File: `web/backend/api/...`
   - Why it matters: clients and contract tests can disagree in staging/production.
   - Evidence: code now returns `registered_domain`; contract does not declare it.
   - Fix: update the versioned contract and matching tests, or remove the field.

## Follow-Up Buckets

- Test hygiene: 4 additional non-blocking test coverage gaps around retry/error branches.
- Cleanup debt: 3 additive wrappers/helpers appear removable after the main logic issue is fixed.
- Contract tidy-up: minor naming consistency issues remain if the team wants a follow-up pass.

## Open Questions

- Short list of assumptions that could not be verified locally.

## What’s Working

- Mention only real strengths.

## Production Consequence & Gaps

- **If this ships as-is:** [what breaks/degrades, what's exposed, blast radius —
  one request / one session / one tenant / cross-tenant / platform-wide]
- **Rollback story:** [feature flag / revertable migration / config toggle /
  "revert the deploy" if nothing faster exists]
- **Gaps found beyond the findings above:** a missing security CI gate
  (`references/security.md`'s Security Gates table), an untested concurrency
  or cross-tenant case, a deferred compliance control — or "none identified,
  verified via [what was checked]". Never leave this blank by omission.

## Review Coverage

- Reviewed: specs/docs/files/tests/config you actually inspected
- Not reviewed: surfaces you could not verify
```

## Enforcement Prompts

Run these mentally before finalizing:

1. Did I verify the design trail (`ADR -> spec -> implementation`)?
2. Did I inspect tests and deployment/config, not just code?
3. Is each finding tied to a broken invariant, contract, or operational property?
4. Did I check tenant isolation, idempotency, retries/timeouts, and authz when relevant?
5. Did I verify Helm/Kubernetes implications for runtime changes?
6. Am I repeating the same root problem in multiple findings?
7. Can several weaker points be collapsed into one stronger finding or one follow-up bucket?
8. Are these findings important enough that a busy human should spend attention on them now?

## Reference Files

Load these on demand while working through the gates:

- `references/principles.md`: Neeve SDLC and production principles
- `references/spec.md`: spec and contract enforcement
- `references/security.md`: always-on security rules
- `references/kubernetes.md`: runtime and K8s deployment checks
- `references/logic.md`: correctness, concurrency, ordering, idempotency
- `references/smells.md`: maintainability and test-smell checks
- `references/typing.md`: mypy/ruff/type-safety checks
- `references/quality-gates.md`: production standard — verify all 7 gates are met by the change under review

---

## Skill Chain

`code-review` is the final quality checkpoint before any change is declared done.
It also feeds backward when findings require spec or implementation changes.

| Situation | Action |
|---|---|
| 🔴 Critical or 🟠 High finding in logic, security, or correctness | → block; author must fix and resubmit to `implement-spec` |
| Finding reveals the spec was wrong or incomplete | → feed back to `to-spec` to amend the spec first |
| Finding reveals missing context about existing behavior | → use `repo-ask` to trace the relevant code before deciding |
| Finding is a DLS visual or token issue | → feed back to `neeve-dls` |
| All findings resolved, quality gates confirmed | → task is done |

**Feeds into:** `implement-spec` (fix loop), `to-spec` (spec amendment)
**Fed by:** `implement-spec` (always), `to-spec` (security-sensitive specs), `neeve-dls` (visual review)

Load `references/quality-gates.md` to verify the change satisfies all 7 gates as part of
every review. A review that does not check all applicable gates is incomplete.
