---
name: implement-spec
description: >
  Implement a scoped engineering spec or work item in the Neeve style. Trigger on: "implement this
  spec", "implement task N", "build this from the spec", "write the code for this work item", "now
  code it", or any request to turn an approved spec or task into production code. Prioritize the
  implementation patterns repeated across backend services, frontend/BFF applications, shared
  libraries, and deployment charts: understand the owned scope first, reuse before creating, preserve ADR/spec
  invariants, use Protocol/contract boundaries, write behaviour-driven tests, maintain strict type
  and quality gates, and verify runtime/Helm consequences before declaring the work done.
---

# Implement-Spec Skill

This skill is for turning an approved spec or work item into real code without drifting off scope or
damaging production behavior.

The default source of truth is:

1. the task or work item being implemented
2. the parent spec, especially `specs/` style specs
3. the actual surrounding codebase
4. repo-local implementation conventions (`AGENTS.md`, `CLAUDE.md`, docs, tests, Helm config)

The job is not to "code aggressively." The job is to implement the owned change correctly, prove
it, and avoid collateral debt.

## Consumer Contract

`implement-spec` consumes the output of `to-spec`.

Its responsibility is to:

- own the FRs assigned to the selected task or slice
- preserve the parent spec's scope, invariants, and non-goals
- stop and decompose the work when the task is too large

It must not silently widen the task just because adjacent work is nearby.

## Neeve Implementation Principles

- **Spec first:** the spec owns scope, sequencing, interfaces, and invariants.
- **Reuse first:** wire or extend existing components before creating new ones.
- **Behaviour over ceremony:** tests prove user-visible or system-visible behavior, not mock trivia.
- **Contract boundaries matter:** Protocols, DTOs, OpenAPI schemas, event payloads, and typed value
  objects are not optional decoration.
- **Deployment reality matters:** if code changes runtime shape, env vars, health endpoints, ports,
  metrics, background workers, or singleton assumptions, the Helm/Kubernetes layer must be checked.
- **Human trust matters:** implementation is not done until someone can explain what changed, why it
  is safe, and what evidence proves it.
- **Sized tasks only:** proceed only when the selected task fits safe implementation boundaries.

## Phase 0 — Task Check

Before writing code, establish the exact owned change.

State:

- what task/work item/spec section is being implemented
- which FRs are owned by this specific task
- what repo and layer(s) are involved
- what is explicitly out of scope
- whether the ask is:
  - new feature work
  - bug fix
  - ADR-driven implementation
  - operational hardening
  - refactor with behavioral constraints

If the task is ambiguous or the spec is missing critical detail, clarify before coding.

### FR ownership rule

For the selected task, all relevant FRs become `implement-spec`'s responsibility.

That means:

- extract the FRs this task is supposed to satisfy
- preserve the surrounding spec context and invariants
- do not claim completion while an owned FR branch remains unimplemented
- do not pull in FRs that belong to another task or follow-on slice

If FR ownership is unclear, stop and resolve that before editing code.

### Task sizing rule

Before coding, size the task.

Default limits:

- `1-3 files` for a clean implementation task
- up to `5 modified files` when the task is primarily changing existing code

If the task exceeds those bounds, do not proceed as-is. First decompose it into smaller
implementation slices.

Use this shape:

```markdown
## Task Check

- **Owned task:** [task / FR / work item]
- **Owned FRs:** [FR numbers or equivalent]
- **Goal:** [plain-English restatement]
- **Primary files / layers:** [expected code surfaces]
- **Out of scope:** [short list]
- **Task sizing:** [fits / requires split]
- **Open questions:** [or "none material"]
```

Do not code until this is clear.

## Phase 1 — Context Absorption

Read before editing.

### Step 1.1 — Read the source of truth

If a spec exists, read the relevant parts, especially:

- Summary / scope
- In scope / out of scope
- Use cases
- Functional requirements
- Invariants
- Edge cases
- Build order / task order
- Required tests / acceptance criteria
- Consequences or follow-on work
- Implementation Handoff

For Neeve specs, assume `specs/` style until the repo proves otherwise.

If no formal spec exists, do not treat reconstruction from code as a general fallback.

Use reconstruction only for bug fixes with clear prior behavior and bounded scope. In that case:

- acknowledge explicitly that no formal spec exists
- name the prior behavior being restored
- reconstruct the minimum source of truth from:
  - ADR or bug report
  - issue description
  - existing tests
  - contracts / docs
  - surrounding code

If the work is a non-trivial feature, a behavior change, or anything that requires inferred scope,
stop and ask the human to invoke `to-spec` first. Do not route around spec creation by inferring
the work from surrounding code alone.

When reconstruction is legitimate, normalize the source into this intake contract:

- owned task
- owned FRs
- in scope
- out of scope
- invariants
- interfaces touched
- required tests
- runtime / Helm impact
- follow-on work excluded from this implementation

### Step 1.2 — Read repo-local conventions

Check the strongest local style sources that apply:

- `AGENTS.md`
- `CLAUDE.md`
- `README*`
- testing guides
- contract docs
- Helm/deployment docs
- **this repo's `context-src/repos/<repo>.yaml` in `neeve-copilot`, if
  registered** — its `do_not_modify` list (call out explicitly before
  touching anything on it), and its documented `test_cmd`/`lint_cmd`. This
  check is mandatory here, not left to whether someone thought to check
  separately.
- **this repo's actual CI workflow** (`.github/workflows/*.yml` or
  equivalent) — every repo has some CI, and CI is the real gate, not the
  yaml's documented commands or this skill's own judgment. Read what CI
  actually runs (lint, type-check, unit/integration tests, security/SCA
  scans) and treat that as the ground truth for "what must pass" — if it
  differs from what `test_cmd`/`lint_cmd` documents, CI wins; flag the
  drift as a gap (a `context-src` fix candidate, proposed the same way
  `repo-intel` proposes one) rather than silently trusting the possibly-stale
  yaml.

**Don't paraphrase away environment quirks when running those commands.**
A repo's real test/lint invocation often isn't the bare tool name — check
for and use whichever of these actually applies before running anything,
and before declaring the task done:
- A Python virtualenv (`.venv`, `venv/`, or a `Pipfile`/`poetry` env) that
  needs activating first (`source .venv/bin/activate`, `poetry run`, etc.)
  — a bare `pytest` outside the right env silently runs against the wrong
  interpreter/dependencies, or fails to import the package at all.
- A `Makefile` target that wraps the raw command with required env vars,
  flags, or setup steps (`make test`, `make lint`) — prefer the `make`
  target over reconstructing the underlying command by hand whenever one
  exists; the wrapping usually exists because the bare command alone
  doesn't work correctly, and CI itself often invokes the same `make`
  target rather than the raw tool.
- Any other repo-specific quirk already captured in `local_dev_env_setup`/
  `test_cmd`/`lint_cmd` (a required exported variable, a required running
  service, a specific working directory) — treat these as load-bearing
  facts to reuse verbatim, not prose to summarize loosely.

**Definition of done includes matching CI, not just running something
locally that looked similar.** If local verification can't exercise
everything CI does (e.g. a scan that only runs in CI infrastructure), say
so explicitly as a gap rather than silently declaring the task complete.

### Step 1.3 — Map the adjacent system

Before editing, identify:

- callers
- dependencies
- data stores / cache keys touched
- events/messages produced or consumed
- contracts or schemas involved
- deployment/config surfaces affected

If the change spans more than one hop, summarize the flow before coding.

### Step 1.4 — Reuse audit

Before introducing any new symbol, ask:

- does something already exist?
- can it be reused as-is?
- can it be extended cleanly?
- if new code is necessary, why is reuse insufficient?

In Neeve repos, duplicate helpers, DTOs, and services are usually a design failure.

## Phase 2 — Implementation Plan

Before writing code, form a small plan for the owned change.

State:

- which files you expect to modify
- what layer each file belongs to
- what tests will prove the change
- what risky invariant or regression you are protecting
- whether the task stays within the sizing rule

Prefer small, mergeable changes that preserve the task boundaries from the spec.

If it does not fit, stop here and decompose before editing.

## Layer Rules

Use the repo’s architecture rather than improvising one.

### Backend / service repos

Typical Neeve pattern:

- **Presentation/API:** routes, handlers, dependency wiring
- **Application:** use cases, orchestration, command/query handling
- **Domain:** entities, value objects, invariants, protocols
- **Infrastructure:** repositories, ORM, cache, NATS/HTTP clients, adapters

Rules:

- Business logic does not belong in route handlers.
- Domain code does not import ORM/framework/infrastructure concerns.
- External integrations are injected through typed boundaries.
- Protocols are preferred to ABC-heavy coupling.

### Frontend / BFF repos

Typical pattern:

- presentational components
- hooks / containers
- typed API services
- client-side state kept minimal and scoped
- contract validation at the boundary when applicable

Rules:

- pure render stays separate from fetching/mutation concerns
- loading/empty/error states are implemented intentionally
- API client behavior matches the owned contract

### Helm / deployment repos

Rules:

- do not treat code as complete if chart/config/runtime wiring is missing
- verify probe, env, resource, securityContext, metrics, and rollout impacts
- production assumptions such as singleton workers must be reflected in Helm

## Bug-Fix Implementation Rule

If implementing a bug fix:

- identify the broken prior behavior first
- implement the smallest change that restores the intended invariant
- write the regression test before or alongside the fix
- do not smuggle in speculative architecture cleanup unless the fix genuinely requires it

Bug fixes in Neeve should close the specific failure mode, not become a disguised rewrite.

Identifying "the broken prior behavior first" is exactly where a shallow grep
finds a plausible-looking cause instead of the real one. If the bug's root
cause isn't obvious from the immediate call site, or depends on how a
third-party library/tool actually behaves, invoke `debug-trace` to trace the
full call chain to its persistence/cache boundary and ground the dependency's
real behavior before writing the fix — don't implement a fix for a
hypothesis that was never actually confirmed. Include the **Depth check**
line (`debug-trace`'s Disclosure Requirement) in the implementation summary
so the root cause claim is auditable, not asserted on confidence alone.

## Test-First Discipline

Before or alongside production code, define the proof.

Tests should map to:

- FRs / acceptance criteria
- use cases
- edge cases
- regressions
- failure modes for retries, persistence, authz, and messaging

Prefer explicit behavior-oriented tests over coverage-chasing noise.

### Neeve test style expectations

Common repo expectations include:

- Given/When/Then structure where the repo uses it
- full type hints, including tests
- clear behavior-describing test names
- unit + integration coverage where the change crosses boundaries
- contract tests when the boundary is versioned or externally consumed

### What to avoid

- tests that only assert a mock was called
- tests that mirror the implementation structure instead of observable behavior
- tests added solely to inflate coverage
- hiding multiple different behaviors behind one giant parametrize block

Load `references/test-patterns.md` for concrete patterns.

## Security And Safety Gate

Before finalizing any implementation that touches user input, persistence, messaging, auth, or
external calls, check:

- validation at the boundary
- fail-closed vs fail-open behavior
- tenant scoping / ownership checks
- timeout and retry behavior
- secrets handling
- logging / PII exposure
- audit obligations

Load `references/security-impl.md` when relevant, and the `code-review` skill's
`references/security.md` for the full OWASP/pentest-mindset/gates/multi-tenancy
checklist rather than re-deriving it. Whatever this gate finds — checked or
skipped — carries forward into the Residual Risks section below; do not let a
check performed here go unstated at completion.

## Async / Worker Gate

When the change touches async flows, workers, or background tasks, check:

- cancellation and shutdown behavior
- lifecycle management
- ordering invariants
- replay / idempotency
- lock/shared-state correctness
- session/transaction scope
- NATS/Redis/DB failure semantics

Load `references/async-patterns.md` when relevant.

## Data Structure And Algorithm Gate

When the change includes non-trivial transformation, indexing, batching, or hot-path loops:

- identify dominant access pattern
- choose the right structure intentionally
- avoid hidden O(n²) paths
- batch external/database access when possible
- stream instead of accumulating when result size is large

Load `references/ds-algorithms.md` when relevant.

## Frontend Gate

When the change includes UI or client logic, verify:

- component responsibility is clear
- state is scoped appropriately
- API responses are typed/validated where the repo expects it
- loading/empty/error states are covered
- user input is normalized and validated appropriately
- auth and forbidden states are surfaced intentionally

Load `references/frontend-impl.md` when relevant.

## Implementation Order

Default order unless the spec says otherwise:

1. test scaffolding / regression proof
2. value objects / contracts / schema changes
3. domain or use-case logic
4. infrastructure wiring
5. route / handler / UI integration
6. Helm or config updates if runtime behavior changed
7. verification and cleanup

Do not skip directly to handler/UI glue if the invariant or contract layer is unsettled.

If the work still exceeds the task sizing rule after ordering it, split it before writing code.

## Verification Requirements

Implementation is not done until verification is run or an inability to run it is reported.

Use repo-appropriate quality gates. Common Neeve expectations:

### Python

```bash
mypy [files] --strict
ruff check [files]
pytest [tests] -v --cov=[module] --cov-report=term-missing --cov-fail-under=95
```

Use `black --check` or repo formatter expectations when applicable.

### TypeScript / frontend

```bash
tsc --noEmit
eslint [files] --max-warnings=0
jest/vitest [tests] --coverage
```

### Contracts / Helm / runtime

Run the relevant checks when the change touches them, for example:

- contract validation/tests
- helm lint / template validation
- targeted integration tests

If you cannot run a relevant check, say so explicitly and explain the residual risk.

## Completion Standard

Before closing the task, verify:

- the owned scope is implemented and non-goals were respected
- no duplicate abstraction was introduced unnecessarily
- tests prove the intended behavior and regression guard
- types/lint/quality gates pass, or failures are clearly reported
- runtime/deployment consequences were accounted for
- any intentional shortcut is named explicitly

Emit this block on every completion, not only when something is outstanding —
an empty-looking "no risks" is a claim that must be backed by what was
verified, the same discipline as this repo's Production Consequence and Gaps
requirement:

```markdown
## Production Consequence

- **What breaks/degrades if this is wrong:** ...
- **Blast radius:** [one request / one session / one tenant / cross-tenant / platform-wide]
- **Rollback story:** [feature flag / revertable migration / config toggle / "revert the deploy"]

## Residual Risks

- [risk not fully validated] — or "none identified, verified via [what was checked]"

## Follow-Up Debt

- [intentional shortcut or deferred cleanup] — or "none"
```

## Anti-Patterns

Do not:

- code before understanding the task boundaries
- implement outside the owned scope just because it is nearby
- create new services/helpers without a reuse audit
- move business logic into framework glue
- let retries/order/cache behavior become implicit
- claim “done” without proof
- ignore Helm/runtime implications for background workers or new env/config needs

## Reference Files

Load on demand:

| File | When to load |
|------|-------------|
| `references/test-patterns.md` | Always when planning or writing tests |
| `references/security-impl.md` | When code touches auth, input, logging, persistence, or external calls |
| `references/async-patterns.md` | When code touches workers, async I/O, retries, lifecycle, or concurrency |
| `references/ds-algorithms.md` | When data structure or algorithm choice materially affects correctness/perf |
| `references/frontend-impl.md` | When the change touches UI, BFF, or browser-facing logic |
| `references/quality-gates.md` | Always — load before writing any code; all 7 gates must pass before done |

---

## Skill Chain

`implement-spec` turns an approved spec into production code. It must not start until
a spec exists and must not finish until all quality gates pass.

| Situation | Prior skill to run first |
|---|---|
| No spec exists yet for the task | → `to-spec` first — do not implement without a spec |
| Spec references unfamiliar code that must be reused | → `repo-ask` to trace the existing pattern |
| Spec references a DLS component | → `neeve-dls` for exact token and component context |

| Situation | Action before declaring done |
|---|---|
| All code written | → run `code-review` skill on the change before marking done |
| Any quality gate fails | → fix and rerun — do not skip or defer |
| A gate is N/A | → write a one-line justification in the Gate Sign-off |

**Feeds into:** `code-review` (always), `to-spec` (if implementation reveals spec gaps)
**Fed by:** `to-spec`, `repo-ask`, `neeve-dls`

## Quality Gate Requirement

Load `references/quality-gates.md` at the start of every implementation task.
All 7 gates must pass. Emit the Gate Summary Checklist before declaring the task done.
A task with any ❌ gate is not done — it is blocked.
