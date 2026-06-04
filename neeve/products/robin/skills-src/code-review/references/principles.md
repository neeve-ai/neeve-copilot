# Neeve SDLC And Production Principles

This reference turns repository conventions into review rules. It is derived from the strongest
patterns repeated across service repositories, frontend/BFF repositories, shared libraries,
deployment-chart repositories, and ADR/design-document repositories.

Use it to decide whether a change is aligned with how Neeve systems are designed, verified, and
deployed.

## 1. Delivery Discipline: ADR -> Spec -> Implementation

Neeve work is expected to leave a traceable design trail.

### What reviewers should expect

- **ADR first** for architectural decisions, cross-service behavior, authz, eventing, data model
  shifts, or major operational changes.
- **Spec or contract next** for feature behavior, acceptance criteria, and owned interfaces.
- **Implementation after design** with tests and deployment wiring following the agreed scope.

### Review implications

- Flag implementation that outruns design.
- Flag scope creep that is not reflected in the spec/work item.
- Flag changes that alter runtime or deployment behavior without updating the Helm/docs layer.

### Strong repo signals

- `adr/README.md`: ADR workflow is propose -> discuss -> accept -> implement.
- `specs/*.md`: work is split into scope, non-goals, interfaces, TDD order, and acceptance
  criteria.
- `docs/contracts/`: versioned contracts and changelogs are part of the delivery model.

If these files do not exist, look for equivalent ADRs, architecture decision records, specs, or
contract definitions in the current repo.

## 2. Interface-Driven Architecture

Neeve favors explicit contracts and swappable boundaries.

### Expected patterns

- Protocol/interface-driven boundaries instead of hard concrete coupling
- Pydantic/OpenAPI contracts at service and API edges
- constructor injection or explicit dependency factories
- small, named abstractions with one business reason to change
- domain logic separated from framework and infrastructure concerns

### Review implications

Flag:

- business logic coupled directly to framework/global state
- hidden singletons or import-time side effects
- untyped or implicit payloads crossing process boundaries
- HTTP or NATS handlers that bypass domain/service contracts
- layer violations such as domain code importing infrastructure/web concerns

### Strong repo signals

- `adr/*interface*architecture*.md`
- `docs/architecture.md`
- `specs/`

If these files do not exist, look for equivalent ADRs, architecture decision records, or contract
definitions in the current repo.

## 3. Contracts Are Owned Surfaces

Public and inter-service behavior must be explicit and versionable.

### Expected patterns

- OpenAPI or equivalent versioned contracts for HTTP integrations
- documented event payloads for NATS/async flows
- typed DTOs or Pydantic models at boundaries
- changelogs/examples for externally consumed contracts

### Review implications

Flag:

- response/request shape drift from the contract
- new fields or semantic changes with no contract update
- consumer-visible behavior hidden only in tests or implementation
- route/event additions that do not appear in owned interface docs

### Strong repo signals

- `docs/CONTRACT_TESTING_GUIDE.md`
- `docs/contracts/`
- `specs/`

If these files do not exist, look for equivalent ADRs, architecture decision records, or contract
definitions in the current repo.

## 4. Correctness Means Replay Safety, Ordering, And Tenant Safety

Many Neeve services are asynchronous, retried, or multi-tenant. Correctness is not just "passes the
happy path."

### Expected patterns

- idempotency for webhook, billing, provisioning, and retry-prone flows
- publish-after-commit or equivalent ordering when durable state and events interact
- explicit retry and failure-classification behavior
- strict tenant scoping by `organization_id` or equivalent owner key
- no authorization decisions based solely on client-controlled data

### Review implications

Flag:

- duplicate side effects under replay
- state updates and event publication in the wrong order
- partial writes across transaction boundaries
- queries or cache keys missing tenant scope
- authz decisions that fail open or trust stale cache without fallback

### Strong repo signals

- `adr/Workitems.md` or equivalent backlog/work-item source-of-truth document
- `specs/SPEC-*.md`
- `docs/architecture.md`

If these files do not exist, look for equivalent ADRs, architecture decision records, specs, or
contract definitions in the current repo.

## 5. Failures Must Be Observable And Contained

Services are expected to degrade predictably, not silently.

### Expected patterns

- structured logging with enough context to correlate failures
- metrics on critical paths and external dependencies
- health endpoints separated by startup/liveness/readiness concerns
- explicit timeout and retry policy on external calls
- graceful shutdown and startup lifecycle handling

### Review implications

Flag:

- missing timeout on network or external service calls
- retries without backoff or retries on non-idempotent operations
- swallowed exceptions or lost exception context
- no logs/metrics around business-critical failures
- health endpoints that are unsuitable for Kubernetes semantics

### Strong repo signals

- `adr/*observability*.md`
- `adr/*logging*.md`
- `charts/docs/PRODUCTION.md` or `deploy/docs/PRODUCTION.md`
- `charts/README.md` or `deploy/README.md`

If these files do not exist, look for equivalent ADRs, architecture decision records, runbooks, or
operability definitions in the current repo.

## 6. Quality Gates Are Part Of The Feature

The test and static-analysis bar is intentionally high.

### Expected patterns

- strict typing (`mypy`, TypeScript strict mode)
- lint/format gates (`ruff`, `black`, `eslint`, `prettier`)
- 95% coverage target for production code paths unless an exception is documented
- behavior-oriented tests, often in Given/When/Then form
- contract tests where interfaces are versioned or consumed by other services

### Review implications

Flag:

- important behavior changes with no test delta
- tests that only prove mocks behave like mocks
- broad mocking that hides integration boundaries
- uncovered negative/failure/replay paths in event-driven or billing/authz code
- loosened type or lint posture without justification

### Strong repo signals

- `adr/*code-standards*quality-gates*.md`
- `docs/contributing.md`
- `docs/TESTING_GUIDE.md`
- `README.md`

If these files do not exist, look for equivalent ADRs, architecture decision records, testing
guides, or quality-gate definitions in the current repo.

## 7. Helm/Kubernetes Is Part Of The System, Not An Afterthought

Everything is deployed in Kubernetes via Helm. Code review is incomplete if it ignores deployment
reality.

### Expected patterns

- hierarchical values structure with env-specific overrides
- startup, liveness, and readiness probes
- resource requests/limits
- secure pod/container security context
- metrics / ServiceMonitor / observability wiring
- rolling upgrade and disruption controls where appropriate
- secrets sourced via refs, not inlined literals

### Review implications

Flag:

- code requiring new runtime config that is not wired through Helm
- chart drift between app assumptions and env values
- missing or weak security context on production workloads
- new service endpoints/ports with no probe or ServiceMonitor consideration
- rollout settings that can cause downtime for stateful or critical services
- changes to vendored/source subcharts without handling packaged chart usage when that repo layout
  requires it

### Strong repo signals

- `charts/docs/CONFIGURATION.md` or `deploy/docs/CONFIGURATION.md`
- `charts/docs/PRODUCTION.md` or `deploy/docs/PRODUCTION.md`
- `charts/docs/GUIDELINES.md` or `deploy/docs/GUIDELINES.md`
- `charts/README.md` or `deploy/README.md`

If these files do not exist, look for equivalent ADRs, architecture decision records,
configuration guides, or deployment definitions in the current repo.

## 8. Release Safety Matters

Neeve repositories document release/hotfix discipline because production safety includes the path to
ship and backport fixes.

### Expected patterns

- branch/release flow respected
- versioned contracts and changelogs updated when needed
- release notes/runbooks updated for operationally meaningful changes

### Review implications

Flag:

- release-sensitive behavior changes with no release note/runbook consideration
- contract version changes without changelog/version policy updates
- fixes on release/hotfix paths that are likely to diverge from mainline branches

### Strong repo signals

- `adr/*branching*release*strategy*.md`
- `docs/RELEASE_RUNBOOK.md`
- `docs/RELEASE_VERSIONING_STRATEGY.md`

If these files do not exist, look for equivalent ADRs, architecture decision records, release
runbooks, or versioning definitions in the current repo.

## 9. Severity Heuristics For Neeve Reviews

Use these heuristics when deciding whether a principle breach is a real finding.

### Usually `CRITICAL`

- broken tenant boundary
- broken authz or fail-open behavior
- event ordering that can permanently desync durable state and downstream consumers
- deploy config that can crash-loop or expose secrets/root privileges unsafely
- contract or migration error that can corrupt or lose production data

### Usually `HIGH`

- missing spec/ADR trail for a cross-service or architectural change
- non-idempotent implementation on replay-prone workflows
- missing timeout/retry/failure handling on critical integrations
- tests that give false confidence on billing/provisioning/authz paths
- Helm/config drift that will make the code change non-deployable or silently wrong

### Usually `MEDIUM`

- local behavior change with weak documentation of intent
- incomplete observability or edge-case coverage
- architecture drift that is contained but trending the wrong way

### Usually `LOW`

- naming, layout, or small refactors with little production effect

## 10. Review Principle

The bar is simple:

`If this merged today and rolled out through Helm to Kubernetes, would the team have peace in production?`

If the answer depends on hope, missing documentation, unverified contracts, or fragile runtime
assumptions, that is the finding.
