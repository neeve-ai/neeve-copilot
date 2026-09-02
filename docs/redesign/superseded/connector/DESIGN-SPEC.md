# Neeve Context Connector — Engineering Spec

> [!WARNING]
> **WITHDRAWN — 2026-09-02. This describes a service that will not be built.**
>
> The `neeve-context` MCP server was justified almost entirely by supporting a browser-only
> population on claude.ai. With that surface out of scope and every population holding a git
> clone, its read plane collapses into a file read and its write plane into a pre-commit
> linter. See decision **D7** in [`../../ARCHITECTURE.md`](../../ARCHITECTURE.md) §15 for the
> scorecard and the trigger condition that would reopen this.
>
> Retained so the reasoning stays findable rather than being rebuilt from scratch.

---

## Metadata

- **Status:** Draft
- **Owner:** unassigned — **see Consequences; this is a blocker for Phase B, not a formality**
- **Version:** 0.1
- **Last Updated:** 2026-08-27
- **Bounded context:** `context-service` — subdomains `registry`, `corpus`, `governance`, `audit`, `ingestion`
- **Related PRD:** `PRD.md` (`neeve-context-connector`) — system of record
- **Related architecture:** `ARCHITECTURE.md` — ADR-1 … ADR-8, design lock conditional
- **Blocks:** PM rollout on claude.ai; retirement of the ~84-line pushed product-overview block
- **Blocked by:** PRD §9 gap 1 (prompt injection undefended) and gap 3 (no service owner) — both Phase B only

---

## Summary

A remote MCP server that serves Neeve's internal knowledge to Claude clients on both
surfaces, and owns the only write path capable of *binding* enforcement for users who have
no filesystem.

**Scope: Layers 04, 03a, and 02 on the read side; governance on the write side**
(ARCHITECTURE ADR-11, superseding ADR-9). Layer 04 (`foundation/`) and Layer 03a
(`process/narrative/`) live in git alongside Layer 03b and are served here as MCP resources.
Layer 03b — gate commands, validation predicates, contracts-as-data — is **not** served: CI
and this service's validators read it straight from git, because a gate must read its rulebook
with no human present to authenticate (ADR-10).

**Storage is not delivery.** Layers 04/03a being stored in git does not make them ambient;
they remain QUERY-channel, pulled on demand, never rendered into the always-on block.

Two planes, deliberately separable (ARCHITECTURE ADR-7). The **read plane** aggregates the
`.help/` book corpus, a repo registry, the PRD/ADR corpus, org facts, and process narrative —
search-then-fetch, staleness-aware. The **write plane** accepts governed
artifacts through deterministic validators that reject rather than warn, and records every
attempt in an append-only audit store that is the only audit trail in existence for this
surface.

---

## Goals

1. Give browser-only users grounded, cited answers about what Neeve already has.
2. Make PM process rules `Blocked` rather than `Advised` — the tier platform prose cannot reach.
3. Answer cross-repo questions cheaply, on both surfaces.
4. Keep freshness a property of the system rather than a habit of its users.
5. Produce an audit trail where the platform provides none.

## Non-Goals

1. **Rendering Layers 04/03a into ambient context.** Stored in git, served on query (ADR-11).
2. **Serving Layer 03b over MCP.** Gates read it from git directly (ADR-10, A-3).
3. Any client relationship with a peer connector. This service does not call Atlassian MCP
   and holds no credential for it.
4. Any UI of our own.
5. Becoming a source of truth (ADR-1) — NotebookLM included, which is a derived projection.
3. Model inference inside the server (ADR-4).
4. Multi-tenancy or external identities.
5. Replacing Atlassian/AWS connectors for live external state.
6. Push, streaming, or resource subscriptions.
7. Design-discipline write tools.
8. Any network path toward OT systems or building equipment.

---

## Definitions

| Term | Definition |
|---|---|
| **Book** | A product repo's committed `.help/` set: `introduction.md`, `index.md`, `appendix.md`, `memory.md`, `lessons.md` |
| **Corpus** | The aggregated, indexed projection of all books plus the PRD/ADR set |
| **Substrate** | The configured artifact store for governed writes: git planning repo, or Confluence + Jira |
| **Workspace binding** | Stage 0 resolution of *where* an artifact will live, before it is drafted |
| **Governed artifact** | An artifact whose creation must pass a validator: PRD, work item, ADR, lesson |
| **Index age** | Wall-clock age of the newest successful ingestion for a given source |
| **Staleness threshold** | Configured age past which reads fail rather than answer (ADR-8) |
| **Bypass** | Any route by which a governed artifact can be written without passing a validator |
| **Actor** | The resolved end-user identity behind a tool call, from the IdP assertion |

### Type aliases

Typed identifiers, not bare `str`:

```
RepoId        = NewType("RepoId", str)          # registry key, e.g. "robin-ai"
ProductId     = NewType("ProductId", str)
FeatureSlug   = NewType("FeatureSlug", str)     # kebab-case, PRD-stable
ActorId       = NewType("ActorId", str)         # IdP subject claim
GroupId       = NewType("GroupId", str)         # SCIM directory group
SectionRef    = NewType("SectionRef", str)      # "<RepoId>#<file>#<heading-path>"
ContinuationToken = NewType("ContinuationToken", str)
AuditSeq      = NewType("AuditSeq", int)        # monotonic, gap-free per shard
```

---

## Assumptions

| ID | Assumption | Impact if wrong |
|---|---|---|
| A1 | Python 3.12 service; repo quality gates (`mypy --strict`, `ruff`, `pytest`) apply | Language change invalidates the DoD's specific gate commands, not the design |
| A2 | EMA is available on the org's plan and the IdP issuer is configurable | Write plane cannot attribute actors; ADR-6 forces write-plane deferral |
| A3 | SCIM group sync is live | No PM-only scoping; read plane becomes org-wide or nothing |
| A4 | Books exist and are non-trivial in the pilot repos | Corpus returns little; the read plane's value is unproven rather than disproven |
| A5 | The org connector admin surface matches the cited documentation for commercial Team/Enterprise | Deployment steps change; **unverified — PRD §12 Q2** |
| A6 | ~150k character result cap and 300s timeout are current | Chunking constants change; the design does not |
| A7 | The raw Confluence/Jira write path can be set to `blocked` per group | **ADR-3's gate is decorative if false. Verify before Phase B** |
| A8 | Planning substrate is git-backed for the pilot | Confluence adapter moves from Phase C to Phase B |
| A9 | `foundation/` and `process/narrative/` exist in `neeve-copilot` as coherent, current prose | The Layer 04/03a read tools serve little. Restructuring the existing `foundation.md` and `engineering-principles.md` into them is a prerequisite task, not part of this build |
| A10 | The model queries the connector for Layer 04/03a rather than answering from priors | If it fails, PMs get confident unsourced answers about Neeve's own identity — worse than the status quo because it *looks* grounded. **ADR-11 reduces but does not remove this risk**: one destination instead of three is easier to route to, not automatic |

**A5 and A7 are unverified and materially affect the design.** A7 in particular determines
whether the central enforcement claim holds at all.

---

## Reuse Inventory

Per `to-spec` Rule 3 (reuse before creating).

| Component | Location | How used in this spec |
|---|---|---|
| Book format and conventions | `neeve/templates/`, product repos' `.help/` | Ingested as-is. **No format change** — the connector adapts to books, never the reverse |
| Freshness-check logic | `neeve/templates/hooks/pre-commit-context-sync` | Staleness semantics reused conceptually; the hook stays local and is not called by the service |
| Org facts, personas | `neeve-copilot/foundation/` (restructured from `foundation.md`) | Ingested read-only and served as a resource. **Reused as-is, not rewritten** — the restructure is a move, not an authoring exercise |
| Process narrative | `neeve-copilot/process/narrative/` (from `engineering-principles.md`) | Ingested read-only and served as a resource |
| Process — executable rules | `neeve-copilot/process/gates/`, extracted to declared data | Read by validators at startup, straight from git. Ends the five-way prose duplication for the *enforceable* subset (ADR-10) |
| PM validation rules | `neeve/references/pm-lens.md` items 1–3 | Mechanised into `create_prd` — the checklist's *checkable* subset only |
| Quality gates | `neeve/references/quality-gates.md` | This spec's DoD |
| Audit conventions | — | **New.** Nothing existing; no prior audit surface in the framework |

**Justification for new components.** The audit store, validators, and index have no
existing counterpart — the framework has never had a service. Everything else adapts to
existing formats rather than introducing a parallel one.

---

## Use Cases

1. **UC-1.** PM with a vague idea learns two-thirds of it exists, before drafting.
2. **UC-2.** PM creates a PRD; the tool rejects it for a missing measurable outcome; PM fixes it; it writes.
3. **UC-3.** Engineer asks which repos a contract touches.
4. **UC-4.** Ingestion stalls; reads refuse rather than answer stale.
5. **UC-5.** Auditor asks who created a PRD and what changed.
6. **UC-6.** A book gains a credential-shaped string; ingestion quarantines rather than indexes it.
7. **UC-7.** Two PMs create the same feature slug concurrently; exactly one artifact exists.
8. **UC-8.** Substrate is down; the write fails cleanly with no partial artifact.

---

## Functional Requirements

### Transport & identity

- **FR-1.** Serve MCP over Streamable HTTP on HTTPS. Legacy HTTP+SSE is not implemented.
- **FR-2.** Accept EMA signed IdP assertions and, for read-only deployments only, static header auth. The `/token` endpoint accepts `application/x-www-form-urlencoded` (RFC 6749) and requires PKCE `S256`.
- **FR-3.** Resolve every call to an `ActorId` and `GroupId` set. **Unresolvable → deny.**
- **FR-4.** Rate-limit per `ActorId`. Platform limits are undocumented; self-throttle.

### Read plane

- **FR-5.** `repo_registry(product?, owner?)` → repos with purpose, ownership, product mapping, and `index_age`.
- **FR-6.** `book_search(query, repo?)` → ranked `SectionRef`s with bounded excerpts, each carrying `RepoId` provenance and `index_age`.
- **FR-7.** `book_fetch(section_ref, continuation?)` → one section, chunked below the result cap, with a `ContinuationToken` when truncated.
- **FR-8.** `prd_search(query)` → matching PRDs/ADRs with slug, status, location.
- **FR-9.** `org_facts` (Layer 04) and `process_narrative` (Layer 03a) exposed as MCP resources, served verbatim from `neeve-copilot/foundation/` and `neeve-copilot/process/narrative/`. Layer 03b is deliberately **not** exposed (ADR-10). *(Retired then reinstated 2026-08-28 — ADR-11.)*
- **FR-10.** Every read response carries `index_age`. Age past the staleness threshold returns a typed staleness error, **never a best-effort answer** (ADR-8).
- **FR-11.** Enforce the result cap server-side. Truncation is always explicit; a silently clipped response is a defect.

### Write plane

- **FR-12.** `create_prd(feature_slug, persona, outcome, workspace, body)` validates: persona non-empty and resolvable against org facts; outcome matches a metric-shaped pattern; workspace bound and known; every cited `RepoId` exists in the registry. **Any failure → reject with the specific failing field.**
- **FR-13.** `create_work_items(feature_slug, items[])` validates dependency ordering is acyclic and topologically sortable, and that each item names an existing `RepoId`.
- **FR-14.** `record_decision(...)` validates context, options-considered, and consequence are all present.
- **FR-15.** `record_lesson(...)` persists a correction with provenance. Sole web path for the feedback loop.
- **FR-16.** Writes are idempotent on `FeatureSlug`: a repeat with identical payload returns the existing location without creating a duplicate; a repeat with a *differing* payload is a conflict error.
- **FR-17.** A rejected write performs **no** substrate side effect.

### Audit

- **FR-18.** Every write attempt — accepted **or** rejected — appends an audit record: `AuditSeq`, `ActorId`, timestamp, tool, parameters, outcome, and content delta on success.
- **FR-19.** Append-only. No update or delete path exists at any layer, including for operators.
- **FR-20.** Audit store unavailable → **writes fail closed.** No unaudited write, ever.
- **FR-21.** Export endpoint for audit records, filterable by actor, time range, and artifact.

### Ingestion

- **FR-22.** Pull `.help/` from each registered repo on an interval using a **read-only** credential. No product repo is modified.
- **FR-23.** Repo registration is configuration, not code.
- **FR-24.** Scan ingested content for credential-shaped strings; quarantine and alert rather than index.
- **FR-25.** Index rebuild from source is idempotent and produces an equivalent index.
- **FR-26.** Ingestion runs in a separate process from request serving, so a stall degrades freshness without degrading latency.

### SOLID mapping

| FR group | Single responsibility | Boundary / inversion |
|---|---|---|
| FR-1…4 | Transport and identity only; knows nothing of artifacts | Authz behind an `IdentityResolver` Protocol; IdP swappable |
| FR-5…11 | Query and shape results; performs no writes | Each source behind a `ReadSource` Protocol; index engine swappable |
| FR-12…17 | Validate, then delegate; never performs I/O itself | `Validator` per artifact type (interface segregation); writes via `SubstrateAdapter` Protocol |
| FR-18…21 | Record; never validates or writes artifacts | `AuditSink` Protocol; append-only enforced at the interface |
| FR-22…26 | Fetch and index; never serves requests | `IngestionSource` Protocol per source kind |

Validators are separate classes per artifact type rather than one branching validator —
adding an artifact type must not modify existing validators.

---

## Invariants

- **I-1.** No write reaches a substrate without passing its validator.
- **I-2.** No write completes without a durable audit record (FR-20).
- **I-3.** A rejected write leaves no substrate side effect.
- **I-4.** Audit records are append-only; no code path updates or deletes one.
- **I-5.** Indexes are derived — deletable and rebuildable with no data loss.
- **I-6.** No tool result exceeds the configured cap; truncation is always signalled.
- **I-7.** No read answers from an index older than the staleness threshold.
- **I-8.** The service performs **zero** model inference calls (ADR-4).
- **I-9.** Unresolved identity denies; unresolved group denies writes.
- **I-10.** Exactly one artifact exists per `FeatureSlug` per substrate.

---

## Workflow / Wiring Story

### Read path

1. Client calls a read tool over Streamable HTTP.
2. Transport verifies the assertion; identity resolver produces `ActorId` + `GroupId`s (FR-3). Unresolved → deny (I-9).
3. Rate limiter admits or rejects (FR-4).
4. Authz maps group → read scopes.
5. `index_age` checked against the threshold (FR-10). Stale → typed error, stop (I-7).
6. Index query; results ranked with `SectionRef` provenance.
7. Result shaper enforces the cap, attaching `ContinuationToken` if truncated (FR-11, I-6).
8. Response carries results, provenance, `index_age`.

### Write path

1. Client calls `create_prd`.
2. Steps 2–4 as above; write scope required.
3. Audit sink reachability probed. Unreachable → deny (FR-20, I-2). *Probed before validation so the failure mode is "cannot accept writes" rather than "validated then lost".*
4. Validator runs — deterministic only (I-8). Failure → audit the rejection (FR-18), return the failing field, stop (I-3, I-17).
5. Idempotency check on `FeatureSlug` (FR-16): identical payload → return existing location; differing → conflict.
6. Substrate adapter writes. Failure → no partial artifact; audit the failure.
7. Audit record appended with content delta.
8. Location returned.

### Ingestion path

1. Worker wakes on interval.
2. Read-only pull per registered repo (FR-22).
3. Secret scan; quarantine on hit (FR-24).
4. Parse `.help/` into sections; build index shard.
5. Atomic index swap; `index_age` updated.
6. Failure leaves the prior index in place and `index_age` ageing — which is exactly what makes ADR-8 fire.

---

## Security

### Fail-closed model

Unresolved identity → deny. Unresolved group → deny writes. Audit unavailable → deny
writes. Index stale → deny reads. Substrate error → deny, no partial write.

### Authentication and authorization

EMA signed IdP assertion (write plane, mandatory per ADR-6); static headers permitted for
read-only pilot. Scopes derived from SCIM groups. Deny by default.

### PII handling

PRD bodies may carry customer-identifying context. Not redacted — treated as
Neeve-internal-confidential, access-controlled, and audited. Audit records store a content
delta, so **the audit store inherits the same classification as the artifacts**, a point
easy to miss when provisioning it.

### Secret management

Service credentials from the platform secret store, never config files. Git credential is
read-only. Substrate credential is a service account scoped to the planning space alone.
Ingested content is secret-scanned (FR-24).

### Input validation surface

Every tool argument is typed and validated. `SectionRef` and `ContinuationToken` are opaque,
server-signed, and rejected if tampered with — they must not be usable to traverse outside
the intended scope.

### Untrusted content into model context

Books and PRDs flow into a model's context (ARCHITECTURE §3.4, TB4). Content is served with
provenance and never framed as instruction. **This is a convention, not a control**, and it
is an open gap (PRD §9 gap 1). It must be resolved before the corpus admits any
third-party-influenced content.

### Audit trail

FR-18…21. The only audit trail for this surface; commercial claude.ai provides none.

### Production consequence if this is wrong

- **Blast radius:** platform-wide for the PM population — all browser users lose all
  grounding simultaneously. Engineers degrade gracefully (local books, git). **The
  degradation is asymmetric.** A validator defect is narrower: one artifact type, one group.
- **Who notices:** PMs immediately on outage; **nobody** on stale-index misinformation until
  a PRD proves wrong downstream — which is why ADR-8 converts it into a loud failure.
- **Rollback / kill-switch:** per-tool `blocked` (seconds, no deploy) → per-group connector
  disable (seconds) → org-wide removal (seconds). Write plane disables independently of
  read (ADR-7). Fallback is manual Confluence authoring: degraded, not blocked.

---

## Interfaces

### Tools

```
repo_registry(product?: ProductId, owner?: str)
  -> { repos: [{ repo_id, purpose, owner, products[] }], index_age: int }

book_search(query: str, repo?: RepoId, limit?: int = 10)
  -> { hits: [{ section_ref, repo_id, heading_path, excerpt, score }],
       index_age: int, truncated: bool }

book_fetch(section_ref: SectionRef, continuation?: ContinuationToken)
  -> { repo_id, heading_path, content, continuation?: ContinuationToken, index_age: int }

prd_search(query: str, status?: str)
  -> { hits: [{ feature_slug, title, status, location, excerpt }], index_age: int }

create_prd(feature_slug: FeatureSlug, persona: str, outcome: str,
           workspace: str, body: str, cited_repos?: [RepoId])
  -> { location: str, version: str }
   | ValidationError { failing_field: str, reason: str, remediation: str }

create_work_items(feature_slug: FeatureSlug, items: [WorkItem])
  -> { location: str, count: int } | ValidationError

record_decision(title: str, context: str, options_considered: [str],
                decision: str, consequence: str)  -> { location } | ValidationError

record_lesson(scope: str, correction: str, provenance: str) -> { id: AuditSeq }
```

### Resources

`neeve://foundation/{personas|customers|identity|product-narrative}` — Layer 04
`neeve://process/narrative/{stages|what-good-looks-like}` — Layer 03a

Both served verbatim from git, with `index_age` and `source_commit` provenance so a citation
resolves to a reviewable commit. **Layer 03b is not exposed** — `process/gates/**` is read
from git at validator startup, never over MCP (ADR-10, invariant A-3).

### Error contract

Typed and machine-actionable, because the caller is a model that must self-correct:

| Code | Meaning | Caller action |
|---|---|---|
| `IDENTITY_UNRESOLVED` | No actor (I-9) | Stop; surface to user |
| `SCOPE_DENIED` | Group lacks scope | Stop; surface |
| `INDEX_STALE` | Age > threshold (I-7) | Stop; report staleness, do **not** answer from priors |
| `RESULT_TRUNCATED` | Cap hit (I-6) | Follow `ContinuationToken` |
| `VALIDATION_FAILED` | Validator rejected | Fix `failing_field`, retry |
| `SLUG_CONFLICT` | Slug exists, payload differs | Reconcile with the human |
| `AUDIT_UNAVAILABLE` | Cannot audit (I-2) | Stop; writes are unavailable |
| `SUBSTRATE_UNAVAILABLE` | Store unreachable | Retry with backoff |

`INDEX_STALE`'s caller action is the load-bearing one: an error the model routes around by
answering from memory reintroduces exactly the failure ADR-8 exists to prevent. The skill
text must state this, and the eval suite must test it.

---

## Data Model

**Audit store** — authoritative, append-only, the only irreplaceable component.

| Column | Type | Constraint |
|---|---|---|
| `seq` | bigint | PK, monotonic |
| `actor_id` | text | not null, `ck_audit_actor_nonempty` |
| `occurred_at` | timestamptz | not null |
| `tool` | text | not null, `ck_audit_tool_known` |
| `outcome` | text | not null, `ck_audit_outcome_enum` (`accepted`/`rejected`/`failed`) |
| `params` | jsonb | not null, secret-scrubbed |
| `delta` | jsonb | null unless `outcome='accepted'`, `ck_audit_delta_iff_accepted` |
| `feature_slug` | text | null |

No `UPDATE` or `DELETE` grant on this table for the service role (I-4) — enforced at the
database privilege level, not only in code, because an invariant defended only in
application code is a convention.

**Index store** — derived, disposable.

| Field | Note |
|---|---|
| `section_ref` | PK; `<RepoId>#<file>#<heading-path>` |
| `repo_id`, `heading_path`, `content`, `tokens` | Searchable projection |
| `ingested_at` | Drives `index_age` |
| `source_commit` | Provenance; enables "as of commit X" |

**Registry** and **process definition**: read-through projections of the framework repo, no
independent persistence.

---

## Edge Cases

- Book missing or partially present → repo indexed with a gap marker; `book_search` never claims coverage it lacks.
- Book renamed/moved heading → `SectionRef` invalid; `book_fetch` returns a typed not-found rather than a nearest guess.
- Tampered `ContinuationToken`/`SectionRef` → rejected (signed).
- Concurrent identical `create_prd` → exactly one artifact (I-10); loser sees existing location.
- Concurrent differing `create_prd`, same slug → one wins, other gets `SLUG_CONFLICT`.
- Substrate write succeeds, audit append fails → **must not be reachable**: audit reachability is probed first and the append is transactional with the write acknowledgement. If it ever occurs, it is a P1.
- Ingestion partially completes → atomic swap means no partial index is ever served.
- Secret detected mid-ingestion → whole shard quarantined, prior index retained, alert raised.
- Empty query → validation error, not a full-corpus scan.
- `outcome` present but vague ("improve things") → **passes** the mechanical check. Honest limitation of ADR-4: omission is caught, vagueness is not.
- Actor resolves, group empty → reads per default scope, writes denied.
- Registry unknown `RepoId` cited in a PRD → `VALIDATION_FAILED`, which is the referential check that most directly prevents the invented-capability failure mode.

---

## Non-Functional Requirements

- **Performance:** read p95 < 2s, p99 < 5s; ingestion of the full corpus < 10 min.
- **Reliability:** stateless request tier, horizontally scalable; ingestion isolated (FR-26). **Availability SLO undefined — owner unassigned. Phase-B blocker.**
- **Observability:** per-tool call count and latency; **rejection-reason distribution** (the signal for whether gates teach or merely obstruct); `index_age` per source; audit-append success rate; secret-quarantine events. Alert on `index_age` approaching threshold *before* reads start failing.
- **Scale:** ~16 repos, ~5 book files each, low-hundreds of PRDs, tens of concurrent users. Comfortably small; do not over-engineer for a scale that is not coming.

---

## Build / Task Order

Each slice sized to `to-spec` Rule 6 (≤3 new files, ≤5 modified).

1. **S1 — Transport + identity skeleton.** Streamable HTTP, EMA/static auth, form-encoded `/token`, PKCE, identity resolver Protocol, deny-by-default. *FR-1…4.*
2. **S2 — Ingestion + index.** Read-only pull, `.help/` parser, secret scan, atomic swap, `index_age`. *FR-22…26.*
3. **S3 — Read plane, registry + books.** `repo_registry`, `book_search`, `book_fetch`, cap enforcement, continuation tokens, staleness gate. *FR-5…7, 10, 11.*
4. **S4 — Read plane, corpus + resources.** `prd_search`, plus `org_facts` and `process_narrative` as resources over the git-sourced Layer 04/03a corpus. *FR-8, FR-9.* — **End of Phase A; deployable and useful.**
5. **S5 — Audit store.** Schema with named constraints, append-only writer, privilege-level enforcement, export. *FR-18…21.* **Precedes any write tool** — I-2 cannot be retrofitted.
6. **S6 — Validators.** Per-type validator classes, error contract, referential checks. *FR-12…14, 17.*
7. **S7 — Substrate adapter, git.** Idempotency on slug, conflict detection. *FR-16.*
8. **S8 — `create_prd` end to end.** Wire S5+S6+S7. — **Phase B gate.**
9. **S9 — Remaining write tools.** `create_work_items`, `record_decision`, `record_lesson`. *FR-13…15.*
10. **S10 — Confluence adapter.** Phase C, or Phase B if A8 is false.

---

## TDD Order

1. Identity resolution and deny-by-default (I-9) before any tool exists.
2. Cap enforcement and truncation (I-6) before any real content is served.
3. Staleness gate (I-7) before the read plane is considered done.
4. Audit append and fail-closed (I-2, I-20) **before the first validator**.
5. Validator rejection with no side effect (I-1, I-3) before any substrate is wired.
6. Idempotency and conflict (I-10, I-16) before concurrency is possible in a real deployment.

---

## Required Tests

Every test carries a `# spec: AC-xx` annotation for CI traceability.

| Use Case | Test ID | Type | What it verifies |
|---|---|---|---|
| UC-3 | T-01 | Unit | `book_search` returns ranked hits with provenance and `index_age` |
| UC-4 | T-02 | Unit | Age > threshold → `INDEX_STALE`, no results |
| UC-1 | T-03 | Unit | Result over cap → truncated flag + `ContinuationToken` |
| UC-1 | T-04 | Integration | `book_fetch` continuation reassembles a full section |
| — | T-05 | Unit | Unresolved identity → `IDENTITY_UNRESOLVED` |
| — | T-06 | Unit | Group without write scope → `SCOPE_DENIED` |
| UC-2 | T-07 | Unit | Missing persona → `VALIDATION_FAILED`, `failing_field='persona'` |
| UC-2 | T-08 | Unit | Non-metric outcome → `VALIDATION_FAILED` |
| UC-2 | T-09 | Unit | Unbound workspace → `VALIDATION_FAILED` |
| UC-2 | T-10 | Integration | Valid payload → artifact created, location returned |
| UC-5 | T-11 | Integration | Accepted write produces audit record with actor, timestamp, delta |
| — | T-12 | Integration | Audit sink down → write denied, substrate untouched |
| — | T-13 | Integration | Repeat identical payload → existing location, no duplicate |
| UC-7 | T-14 | Integration | Two concurrent identical creates → exactly one artifact |
| UC-7 | T-15 | Integration | Concurrent differing creates, same slug → one `SLUG_CONFLICT` |
| UC-8 | T-16 | Integration | Substrate down → clean failure, no partial artifact |
| UC-5 | T-17 | Integration | Rejected attempt is audited with `outcome='rejected'` |
| UC-4 | T-18 | Integration | Index deleted then rebuilt → equivalent index (I-5) |
| UC-6 | T-19 | Integration | Credential-shaped string → quarantined, prior index retained |
| — | T-20 | Unit | Zero model-inference calls across the full request surface (I-8) |
| — | T-21 | Unit | Unordered/cyclic dependencies → `VALIDATION_FAILED` |
| — | T-22 | Integration | `record_lesson` persists and is retrievable |
| — | T-23 | Unit | PRD citing unknown `RepoId` → `VALIDATION_FAILED` |
| — | T-24 | Unit | Tampered `SectionRef`/`ContinuationToken` → rejected |
| — | T-25 | Regression | `UPDATE`/`DELETE` on audit table denied at privilege level (I-4) |
| UC-4 | T-26 | Regression | Ingestion failure leaves prior index served and `index_age` ageing |
| UC-1 | T-27 | Unit | `prd_search` returns matching PRDs with slug, status, location and `index_age` |
| — | T-28 | Unit | `neeve://foundation/personas` returns verbatim content with `source_commit` provenance |
| — | T-29 | Regression | No MCP tool or resource exposes `process/gates/**` — the A-3 boundary holds |

### FR-to-test mapping

| FR | Tests |
|---|---|
| FR-1…4 | T-05, T-06, T-24 |
| FR-5…7 | T-01, T-03, T-04 |
| FR-8 | T-27 |
| FR-9 | T-28, T-29 |
| FR-10, 11 | T-02, T-03, T-26 |
| FR-12 | T-07, T-08, T-09, T-10, T-23 |
| FR-13 | T-21 |
| FR-14, 15 | T-22 |
| FR-16 | T-13, T-14, T-15 |
| FR-17 | T-07, T-12, T-16, T-17 |
| FR-18…21 | T-11, T-12, T-17, T-25 |
| FR-22…26 | T-18, T-19, T-26 |

---

## Acceptance Criteria

- **AC-01:** Given an index newer than the staleness threshold, When `book_search` is called with a query matching content in two repos, Then hits from both repos are returned with `section_ref`, `repo_id`, and `index_age`.
- **AC-02:** Given an index older than the staleness threshold, When any read tool is called, Then `INDEX_STALE` is returned and no content is included.
- **AC-03:** Given a section larger than the result cap, When `book_fetch` is called without a continuation token, Then the response is truncated below the cap, `truncated` is true, and a `ContinuationToken` is present.
- **AC-04:** Given a truncated `book_fetch` response, When `book_fetch` is called with its `ContinuationToken`, Then the next chunk is returned and concatenation reproduces the source section byte-for-byte.
- **AC-05:** Given a request whose identity assertion cannot be resolved, When any tool is called, Then `IDENTITY_UNRESOLVED` is returned and no index or substrate access occurs.
- **AC-06:** Given an actor in a group without write scope, When `create_prd` is called with a valid payload, Then `SCOPE_DENIED` is returned and no artifact is created.
- **AC-07:** Given a `create_prd` payload with an empty persona, When the tool is called, Then `VALIDATION_FAILED` is returned with `failing_field='persona'` and a non-empty `remediation`, and no substrate write occurs.
- **AC-08:** Given a `create_prd` payload whose outcome does not match a metric-shaped pattern, When the tool is called, Then `VALIDATION_FAILED` is returned with `failing_field='outcome'`.
- **AC-09:** Given a `create_prd` payload whose workspace is absent or unknown, When the tool is called, Then `VALIDATION_FAILED` is returned with `failing_field='workspace'`.
- **AC-10:** Given a fully valid `create_prd` payload and a reachable substrate and audit sink, When the tool is called, Then the artifact is created and a `location` and `version` are returned.
- **AC-11:** Given a successful `create_prd`, When the audit store is queried for that `feature_slug`, Then exactly one record exists with `outcome='accepted'`, the calling `actor_id`, a timestamp, and a non-null `delta`.
- **AC-12:** Given an unreachable audit sink, When `create_prd` is called with a valid payload, Then `AUDIT_UNAVAILABLE` is returned and the substrate contains no new artifact.
- **AC-13:** Given a PRD already created for a slug, When `create_prd` is called again with a byte-identical payload, Then the existing `location` is returned and the substrate artifact count is unchanged.
- **AC-14:** Given two concurrent `create_prd` calls with the same slug and identical payloads, When both complete, Then exactly one artifact exists and both callers receive the same `location`.
- **AC-15:** Given two concurrent `create_prd` calls with the same slug and differing payloads, When both complete, Then exactly one succeeds and the other receives `SLUG_CONFLICT`.
- **AC-16:** Given an unreachable substrate, When `create_prd` is called with a valid payload, Then `SUBSTRATE_UNAVAILABLE` is returned, no partial artifact exists, and an audit record with `outcome='failed'` is appended.
- **AC-17:** Given a `create_prd` call that fails validation, When the audit store is queried, Then a record exists with `outcome='rejected'` and the failing field in `params`.
- **AC-18:** Given a populated index, When the index store is deleted and ingestion re-run against unchanged sources, Then `book_search` for a previously-matching query returns the same `section_ref` set.
- **AC-19:** Given a book containing a credential-shaped string, When ingestion runs, Then that shard is quarantined, the string appears in no index or tool result, the prior index remains served, and an alert is emitted.
- **AC-20:** Given the full tool surface exercised end to end, When inference-call instrumentation is inspected, Then the count of model inference calls made by the service is zero.
- **AC-21:** Given a `create_work_items` payload whose dependency graph contains a cycle, When the tool is called, Then `VALIDATION_FAILED` is returned identifying the cycle, and no items are created.
- **AC-22:** Given a `create_prd` payload citing a `RepoId` absent from the registry, When the tool is called, Then `VALIDATION_FAILED` is returned with `failing_field='cited_repos'`.
- **AC-23:** Given a `SectionRef` or `ContinuationToken` whose signature does not verify, When `book_fetch` is called with it, Then the request is rejected and no content outside the caller's scope is returned.
- **AC-24:** Given the service database role, When an `UPDATE` or `DELETE` is attempted against the audit table, Then the database rejects it on privilege grounds.
- **AC-25:** Given a running service with a populated index, When ingestion fails on its next cycle, Then reads continue served from the prior index with `index_age` increasing, until the threshold is crossed and AC-02 applies.
- **AC-26:** Given a PRD corpus containing a document matching a query, When `prd_search` is called with that query, Then the response includes that document's `feature_slug`, `status`, `location`, and `index_age`.
- ~~**AC-27:** Given any tool call, When the response is inspected, Then it contains no Layer 03/04 content…~~ *(removed 2026-08-28: contradicted by ADR-11, which brings Layers 04/03a into this service. Retired rather than deleted per the AC-retirement convention.)*
- **AC-28:** Given a request for `neeve://foundation/personas`, When the resource is read, Then the content is returned verbatim from `foundation/` with `source_commit` and `index_age` provenance.
- **AC-29:** Given the full MCP surface enumerated, When it is inspected, Then no tool or resource exposes `process/gates/**` — Layer 03b is readable only from git by CI and validators, never over the network.

---

## Definition of Done

Per `neeve/references/quality-gates.md`, all seven gates, adapted to a Python service (A1):

- [ ] **Gate 1 — Linter:** `ruff check` zero warnings.
- [ ] **Gate 2 — Types:** zero `mypy --strict` errors.
- [ ] **Gate 3 — Unit tests:** ≥ 95% line **and** branch coverage.
- [ ] **Gate 4 — Integration tests:** T-04, T-10…T-19, T-22, T-25, T-26 pass against a real index and a scratch substrate.
- [ ] **Gate 5 — Scale check:** full-corpus ingestion < 10 min; read p95 < 2s at expected concurrency.
- [ ] **Gate 6 — Security check:** fail-closed paths tested (AC-02, 05, 06, 12, 16); secret scan verified (AC-19); token tampering rejected (AC-23); audit immutability enforced at privilege level (AC-24).
- [ ] **Gate 7 — Code review:** per `code-review` skill, with security focus — this service is a new authenticated internet-facing surface holding an aggregate of internal knowledge.
- [ ] Every AC has ≥ 1 annotated test (`# spec: AC-xx`).
- [ ] All DB constraints use explicit `name="ck_…"`.
- [ ] Observability metrics implemented, including **rejection-reason distribution**.
- [ ] Production consequence and gaps stated (below) — not left blank.
- [ ] **A7 verified**: the raw Confluence/Jira write path can be and is set to `blocked` for the PM group. **Without this, every validator here is decorative** (ADR-3).

---

## Consequences / Follow-on Work

**Production consequence.** A new authenticated internet-facing service holding the
aggregate of Neeve's internal knowledge. Outage removes *all* grounding for browser users
simultaneously while engineers degrade gracefully — the asymmetry is structural and PMs get
the worse half. The worst failure is not outage but **silent staleness**, which ADR-8
converts into a loud refusal precisely because nobody notices the quiet version. Blast
radius: platform-wide for the PM population; one artifact type and one group for a validator
defect. Rollback: per-tool `blocked` → per-group disable → org-wide removal, all in seconds,
with manual Confluence authoring as a degraded fallback.

**Gaps / residual risk — named.**

1. **Prompt injection across TB4 is undefended.** Provenance labelling is a convention, not a control. Blocks admitting any third-party-influenced content. *PRD §9 gap 1.*
2. **No availability owner and no SLO.** Largest non-technical gap; **blocks Phase B.** *PRD §9 gap 3.*
3. **A7 unverified.** If the raw write path cannot be blocked per group, ADR-3's enforcement claim fails and the design needs rework, not tuning.
4. **A5 unverified.** Commercial-tier admin surfaces assumed equivalent to government-tier documentation.
5. **Vagueness is not caught.** ADR-4's mechanical validators catch omission only; "improve things" passes as an outcome. Accepted for v1; revisit only with evidence it matters.
6. **Discoverability unproven.** The design assumes the model queries rather than answering from priors. Phase A exists to test this; if it fails, the read plane returns little regardless of quality.
7. **Corpus quality caps output.** Books are uneven and TS/Go symbol detection is conservative. The service cannot exceed its sources.
8. **CI cannot call this connector.** Engineer-side `Blocked` gates stay git/CI-local; a service-account path is unscoped.
9. **Concentration risk, enlarged by ADR-11.** An outage now costs PMs Layers 04 and 03a as
   well as 02. Three peers became two — better routing, wider blast radius. Raises the stakes
   on gap 2 rather than adding a separate gap. *PRD §9 gap 9.*
10. **Federated discovery still has no single entry point**, though the gap narrowed from
    three systems to two. A silently missing source still reads as "no prior art exists," so
    per-source status labelling remains required. *PRD §9 gap 10.*
11. **A10 unverified.** The design assumes the model queries the connector for Layer 04/03a
    rather than answering from priors. ADR-11 reduces this risk — one destination instead of
    three — but does not remove it. If it fails, PMs receive confident unsourced claims about
    Neeve's own identity, which *look* grounded and are therefore worse than the current gap.
12. **Layer 04 authoring by non-engineers** relies on a PR through GitHub's web UI. Adequate
    at quarterly cadence; a `propose_foundation_change` tool is out of scope. *PRD §9 gap 11.*
13. **Depth check:** transport, auth modes, result-cap and timeout figures, resource/prompt support, and the absence of a commercial audit API were grounded in current vendor documentation during research. Not grounded: A5, A7, and whether a browser Claude Code surface exists (PRD §12 Q1) — that last one could change the two-channel premise this spec rests on.

**Follow-on work.** Confluence adapter (S10) · `domain-intel` skill over the corpus ·
engineer-side cross-repo reads · corpus-quality metrics feeding `repo-intel` refresh
priority · eval suite per skill once `claude plugin eval` is generally available.

---

## Implementation Handoff

- **Owned task or slice:** S1 — transport and identity skeleton.
- **Owned FRs:** FR-1, FR-2, FR-3, FR-4.
- **Implement now:** Streamable HTTP MCP endpoint over HTTPS; EMA assertion verification and static-header mode; `/token` accepting `application/x-www-form-urlencoded` with PKCE `S256`; `IdentityResolver` Protocol with an IdP implementation; per-`ActorId` rate limiter; deny-by-default authz returning `IDENTITY_UNRESOLVED` / `SCOPE_DENIED`.
- **Do not implement now:** any read tool beyond a health probe; any write tool; audit store; ingestion; index; substrate adapters. **Do not stub a write tool "for wiring"** — I-1 and I-2 must never be bypassable, including in dev.
- **Invariants to preserve:** I-8 (no model calls — establish this in S1 and keep it true), I-9 (unresolved identity denies).
- **Required tests before done:** T-05, T-06, T-24.
- **Runtime / Helm impact:** new service, new chart — one Deployment (request tier), one CronJob or worker Deployment reserved for ingestion in S2, one Secret for IdP config, one Ingress with TLS. No changes to existing charts.
- **Task sizing / decomposition note:** fits 3 new files (`transport.py`, `identity.py`, `authz.py`) plus chart scaffolding. Within Rule 6 bounds. S2 and S5 should each be re-checked for splitting before they start, since both touch persistence.
