# Neeve Engineering — Agent Instructions

Read by: GitHub Copilot · OpenAI Codex · Google Antigravity · Claude Code · Cursor

This file is rendered, not hand-edited, into every repo's `AGENTS.md`,
`.github/copilot-instructions.md`, `CLAUDE.md`, and `.cursorrules` by
`scripts/context_render.sh`. Edit `context-src/base.md` and the relevant
`context-src/repos/<repo>.yaml` — never edit a rendered file directly, it will
be overwritten and flagged as drift by `context-drift-check` CI.

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

{{PRODUCT_OVERVIEW_FRAGMENT}}

{{PRODUCTION_CONSEQUENCE_FRAGMENT}}

---

## This Repo

{{REPO_STACK_BLOCK}}

{{REPO_LOCAL_DEV_BLOCK}}

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
| `repo-intel` | Ask to map/document this repo, generate CONTEXT.md | `/repo-intel` / `$repo-intel` |
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
