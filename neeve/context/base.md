# Neeve Engineering — Agent Instructions

Read by: GitHub Copilot · OpenAI Codex · Google Antigravity · Claude Code · Cursor

This file is the source for the house-rules variant that
`scripts/context_render.py --house-rules` renders and `install.sh` installs
once, globally, per engineer (`~/.claude/CLAUDE.md`, Copilot's
`instructions/`, etc.) — never committed into any product repo. Edit this
file and the product-level fragments/product overview; never hand-edit a
rendered output file, it will be overwritten on the next install.

---

## Why This Matters

Neeve builds the security and control layer for smart buildings and critical
infrastructure — commercial real estate, industrial OT, healthcare, transportation.
Code here often sits between an operator and physical equipment. Three defaults
should shape every suggestion and every review comment:

- **Zero-trust by default.** Any new network path, credential, or trust boundary
  should assume breach, not perimeter safety. Prefer short-lived, scoped credentials
  over standing access. Flag anything that resembles a VPN-style "trusted network"
  assumption — that model is exactly what Neeve replaces for customers.
- **Simplify, don't accrete.** Neeve's product pitch is turning fragmented,
  complicated systems into one coherent surface. Hold code to the same standard:
  prefer removing a special case over adding a flag for it, and prefer extending an
  existing integration point over building a parallel one.
- **State the operational stakes.** When reviewing or explaining a change, name the
  business/operational consequence (downtime on a building system, an exposed
  credential, a support cost) alongside the technical one — not instead of it.

These are judgment defaults, not a checklist — apply them where they change a
decision, not as boilerplate to append to every response.

Full reasoning for these defaults, what Neeve is and who it serves:
`neeve/foundation.md`. The fuller SDLC process-principles charter (PRD/
Design/Spec/Implementation/Review, each stage's principles stated
explicitly): `neeve/engineering-principles.md`.

---

## Always On: The Process and The Map

These rules are not skill-specific and do not wait for a skill to trigger.
They apply to *every* turn in *any* Neeve product repo — a one-line question,
a quick edit, a full feature — so that the process is inherited automatically
and no engineer (or non-engineer) has to remember to invoke it. All are
cheap; skipping them is the expensive path.

### 1. Read the repo's map before grepping cold — always

Most Neeve product repos carry a committed **OKF book** under `.help/`:
`.help/introduction.md` (what/why), `.help/index.md` (functional area →
file globs → entry points), `.help/appendix.md` (symbol-level detail), and
the working-memory pair `.help/memory.md` / `.help/lessons.md`. It exists
precisely so an agent does not start every task with a blind repo-wide grep.

Before answering a "how/why/where" question, or editing code, in a repo that
has `.help/`:

1. **Read `.help/index.md` first** to jump straight to the files that matter,
   and check `.help/appendix.md` for the symbols you are about to touch.
2. **Trust, but verify freshness.** `.help/introduction.md`'s frontmatter
   records `book-verified-commit` — the SHA the book was last confirmed
   accurate at. If the repo ships the context-sync hook, run
   `python3 .githooks/pre-commit --all` (a full audit whose findings include
   drift since that checkpoint), or directly eyeball `git log
   <book-verified-commit>..HEAD -- <files you care about>`. If the specific
   files you are relying on have **not** changed since that commit, treat the
   book as an authoritative map. If they **have** changed (or there is no
   `book-verified-commit` yet), **downgrade the book to a hint**: read the
   actual code as the source of truth, and note the drift so it can be
   re-mapped with `repo-intel`.
3. **The book is a map, never proof.** Code is always the source of truth;
   the book only tells you where to look faster. Never cite the book for a
   fact you could not also confirm in the code.

If a repo has **no** `.help/` book yet, say so and offer to run `repo-intel`
to create one — don't silently fall back to cold grepping as if that were
the only option.

### 2. Follow the Design Loop — don't jump straight to code

For anything beyond a trivial one-line fix, the expected path is `to-spec` →
human review of the spec → `implement-spec` → `code-review`, never straight
to implementation (see Engineering Principles below). The right skill
usually auto-triggers on phrasing; if it doesn't, invoke it. **Never assume
— verify:** an existing helper, a contract's real shape, a downstream
service's behavior, a config value. When verifying is out of scope, name the
assumption as a gap rather than presenting a guess as fact.

**Right-size the process — and ask when it's genuinely ambiguous.** The
Design Loop is the default for customer-facing features and anything that
touches a production system, not a toll booth every task must pass through.
An internal tool, a one-off script, a minor bugfix, or small
maintenance/refactor work can reasonably skip PRD/ERD (and sometimes a full
spec) — that is expected, not a violation. Two things follow from that:

- **Don't manufacture process for something that doesn't need it.** Forcing a
  PRD, an ERD, or a heavyweight spec onto a five-line internal script is
  scope bleed applied to process itself — the same failure mode Engineering
  Principles calls out for code.
- **When the size/blast-radius of the task is genuinely unclear, ask —
  don't silently assume either way.** "This looks like an internal
  script/quick fix — want the full Design Loop, or should I just implement
  it directly?" costs one question; guessing wrong costs either an
  unreviewed change to something that mattered, or bureaucracy on something
  that didn't. Default to asking when a request could plausibly be either.
- **A lighter path taken deliberately is not a gap to retroactively enforce
  against.** If a task started without a PRD because it was reasonably
  judged out of scope for one, later stages must not backfill a PRD/Decision
  Log requirement onto it just because the Design Loop machinery exists —
  that would be enforcing process downstream onto a decision that was made,
  not missed. The System-of-Record rule below only ever applies once a PRD
  actually exists for the feature.

**The PRD is the system of record — scoped to features that have one.** When
a feature has a PRD, it is the single source of truth through Design, ERD,
Spec, and Implementation — one git-versioned document, not a kickoff doc
that goes stale. Any later phase that changes the PRD's scope, a
requirement, an assumption, or a decision writes it back into the PRD in the
same commit — the affected section edited, a Change & Decision Log row added
with the *why*, and `Status:` advanced — never leaving a downstream doc
silently contradicting it. This does not apply, and must never be invoked
retroactively, on work that never had a PRD in the first place. See
`neeve/references/prd-system-of-record.md`.

### 3. Work in the full product workspace, not a single repo

Neeve products are built the way modern, scalable enterprise SaaS + AI
products are: many independently-deployed services and shared libraries that
only hold together through the seams *between* them. Those seams are not just
data contracts (API shapes, DB schemas/migrations, event/NATS payloads, MCP
tool schemas, shared DLS components) — they are the full set of cross-cutting
concerns that decide whether a distributed product actually works in
production:

- **Identity & tenancy** — authN/authZ, session/token flow, and the
  multi-tenant isolation boundary that must be enforced consistently across
  every service, not per-repo.
- **AI/LLM contracts** — prompt/tool/eval definitions, model and context
  boundaries, guardrails, and the advisory-vs-actuating line (Robin is
  supervisory by design) — held to the same rigor as an API contract.
- **Operational surface** — observability (logs/metrics/traces), feature
  flags and config, rate limits/quotas, idempotency, and the
  deploy/Helm/Kubernetes topology that ties services together.
- **Reliability & rollout** — versioning and backward compatibility of shared
  libraries and contracts, migration ordering, and the rollback/kill-switch
  story for anything customer-facing.

A change is only "done" when its effect across these seams is verified in the
*actual consumer's code*, not assumed. The intended setup is therefore a
single **workspace** with all of a product's repos checked out side by side,
so those facts can be read directly. Do not hardcode a workspace path —
discover it by searching up from the current directory for the sibling repos.

At the start of cross-repo work:

- **Assess which product this workspace is** — match the repos present
  against the known-products registry (`neeve/products/*/context/
  product-overview.md`, one entry per product, `robin` today; more as they
  are added). Read the matched product's overview so its persona and problem
  statement are grounded, not guessed. If the workspace matches no known
  product, say so rather than inventing one.
- **If a repo you need to verify against is missing from the workspace, do
  not assume it matches** and do not clone into a guessed path. State the
  missing repo as a gap, and ask the user to relaunch the session with the
  full product workspace (all the desired repos) checked out together.

{{PRODUCT_OVERVIEW_FRAGMENT}}

{{PRODUCTION_CONSEQUENCE_FRAGMENT}}

---

## Engineering Principles

- **Spec first.** The spec owns scope, sequencing, interfaces, and invariants.
  Read it before writing code.
  For non-trivial changes, the expected SDL path is `to-spec` -> human review of the spec ->
  `implement-spec` -> `code-review`; do not skip straight to implementation.
- **Reuse first.** Verify no existing component covers the need before creating a
  new class, service, table, or helper. In Neeve repos, duplicate helpers and DTOs
  are a design failure.
- **Behaviour over ceremony.** Tests prove user-visible or system-visible behavior,
  not that a mock was called. Every test traces to an FR, acceptance criterion, or
  user journey.
- **Contract boundaries matter.** Protocols, DTOs, OpenAPI schemas, event payloads,
  and typed value objects are not optional decoration.
- **Deployment reality matters.** If code changes runtime shape — env vars, health
  endpoints, ports, metrics, background workers, singleton assumptions — the
  Helm/Kubernetes layer must be checked.
- **No speculative code.** Only implement what the current task requires.
  Code added "just in case" is debt on day one.

---

## Quality Gates

Apply to every file changed, regardless of size.

**Python:**
```bash
mypy [files] --strict            # 0 errors
ruff check [files]               # 0 violations
pytest [tests] -v --cov=[module] --cov-fail-under=95
```

**TypeScript / JavaScript:**
```bash
tsc --noEmit                     # 0 type errors
eslint [files] --max-warnings=0
jest/vitest [tests] --coverage
```

**Helm / Kubernetes:**
```bash
helm lint [chart]
helm template [chart] | kubectl apply --dry-run=client -f -
```

{{REPO_COMMANDS_BLOCK}}

---

## Architecture Layer Rules

```
Domain:          entities, value objects, invariants, protocols
                 — NO ORM, NO framework, NO infrastructure imports
Application:     use cases, orchestration, command/query handling
                 — NO direct DB/HTTP/NATS calls
Infrastructure:  repositories, ORM, NATS/HTTP clients, cache adapters
Presentation:    routes, handlers, workers, CLI entry points
                 — thin glue only, NO business logic
```

Never put business logic in route handlers.
Never import infrastructure concerns into the domain layer.
Inject dependencies through typed protocols, never instantiate inside business logic.

{{REPO_DO_NOT_MODIFY_BLOCK}}

---

{{SPEC_REVIEW_FRAGMENT}}

{{CODE_REVIEW_FRAGMENT}}

{{OT_DOMAIN_FRAGMENT}}

{{DLS_FRAGMENT}}

## Skills Available

These skills are installed per-repo and globally. They trigger automatically
when the description matches your request, or invoke manually.

| Skill | Triggers when you... | Manual invoke |
|-------|---------------------|---------------|
| `to-prd` | Ask to turn a problem into a PRD | `/to-prd` / `$to-prd` |
| `to-erd` | Ask to break a PRD into engineering work items | `/to-erd` / `$to-erd` |
| `repo-intel` | Ask to map/document this repo, fill or refresh its OKF book (`.help/introduction.md`/`.help/index.md`/`.help/appendix.md`) | `/repo-intel` / `$repo-intel` |
| `repo-ask` | Ask how/why something works, trace a call path | `/repo-ask` / `$repo-ask` |
| `to-spec` | Ask to write a spec, plan a feature, or break into tasks (includes Design/architecture lock, Stage 2 of the Design Loop) | `/to-spec` / `$to-spec` |
| `implement-spec` | Ask to implement a task, build from a spec, or write code | `/implement-spec` / `$implement-spec` |
| `code-review` | Ask to review, audit, or check production readiness | `/code-review` / `$code-review` |
| `neeve-dls` | Ask to update a DLS component or match a design | `/neeve-dls` / `$neeve-dls` |
| `ot-building-automation` | Ask about Niagara/BQL/WebCTRL building-automation work | manual invoke, or auto-triggers in `alc-*`/`niagara-robin-agent` |
| `debug-trace` | Invoked *by another skill/agent* when a step needs exhaustive, research-grounded depth — not a typical first move | manual invoke, or ask to "trace this thoroughly" / "don't just grep this" |

The full Design Loop, all 8 stages (see `neeve/README.md`): `to-prd` (PRD) →
`neeve-dls` PRD Prototype Mode (optional, UI only) → `to-erd` (work-item
breakdown) → `to-spec` (Spec, including the Design/architecture lock) →
`implement-spec` (Implement; all 7 quality gates must pass) → `code-review`
(Code Review; loops back if findings require changes) → Merge → CI Pass,
which re-enters the loop at the next feature's PRD. `repo-ask`/`repo-intel`
run ahead of any stage to orient in unfamiliar code. `debug-trace` sits
outside this chain, one level deeper — every other skill invokes it at the
specific step that needs exhaustive call-chain tracing or real (not
remembered) research into an external library/tool/concept.

Not every change needs every stage — a small bug fix starts at `to-spec`,
not `to-prd`.

## The `neeve` Agent

One unified agent, `neeve`, routes across all of the above by Design Loop
stage and handles setup/onboarding — see its own `AGENT.md` for the full
routing table. Invocation differs by tool (researched directly against each
tool's mechanism, not assumed): Claude Code auto-triggers it or `/agent`;
Copilot (VS Code) surfaces it in the agent picker (skills still auto-trigger
independently there); Codex gets a native agent; Cursor/Antigravity get the
same content as a skill fallback (which auto-triggers, unlike Copilot's
picker). On Claude Code specifically, this agent is often redundant with
its own auto-routing to the skills directly — the skills are the reliable
surface across every tool; the agent is the routing/setup layer on top.

## Prompt Files (slash commands)

If your editor surfaces `.github/prompts/*.prompt.md` as slash commands, the
same skills are available as `/to-prd`, `/to-erd`, `/to-spec`,
`/implement-spec`, `/code-review`, `/repo-ask`, `/repo-intel`, `/neeve-dls`,
`/debug-trace` — thin wrappers around the skills above, useful where
automatic skill-matching doesn't trigger (e.g. inline chat).
