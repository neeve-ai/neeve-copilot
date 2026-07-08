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

Full reasoning lineage for these defaults, plus the fuller Product/Design/
Engineering charter (each principle traced to a named industry practice) and
customer/buyer-persona detail: `neeve/org/PRINCIPLES.md`.

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
| `repo-intel` | Ask to map/document this repo, generate CONTEXT.md | `/repo-intel` / `$repo-intel` |
| `repo-ask` | Ask how/why something works, trace a call path | `/repo-ask` / `$repo-ask` |
| `to-spec` | Ask to write a spec, plan a feature, or break into tasks | `/to-spec` / `$to-spec` |
| `implement-spec` | Ask to implement a task, build from a spec, or write code | `/implement-spec` / `$implement-spec` |
| `code-review` | Ask to review, audit, or check production readiness | `/code-review` / `$code-review` |
| `neeve-dls` | Ask to update a DLS component or match a design | `/neeve-dls` / `$neeve-dls` |
| `debug-trace` | Invoked *by another skill/agent* when a step needs exhaustive, research-grounded depth — not a typical first move | manual invoke, or ask to "trace this thoroughly" / "don't just grep this" |

The skill chain: `repo-ask`/`repo-intel` (understand) → `to-spec` (agree scope) →
`implement-spec` (build; all 7 quality gates must pass) → `code-review` (final
checkpoint; loops back if findings require changes). `neeve-dls` runs alongside
`implement-spec` for UI/DLS surfaces. `debug-trace` sits outside this chain,
one level deeper than `repo-ask` — every other skill/agent invokes it at the
specific step that needs exhaustive call-chain tracing or real (not
remembered) research into an external library/tool/concept, rather than
re-deriving that rigor inline.

The full north-star pipeline, when a feature starts from a product idea
rather than an existing spec: `to-prd` (PRD) → `neeve-dls` PRD Prototype Mode
(optional, UI only) → `to-erd` (work-item breakdown) → the chain above,
once per work item.

## Agents Available

Unlike skills, these are specialist agents, not always-loaded workflows —
and **invocation is not identical across tools** (researched directly
against each tool's mechanism, not assumed): Claude Code and Codex auto- or
explicitly-invoke a real native agent; Copilot in VS Code shows them in an
agent picker rather than auto-triggering by default; Cursor and Antigravity
have no native agent concept, so they get the same content as a Skill
instead (which does auto-trigger — more automatic than Codex's explicit-only
agents, not less).

| Agent | Does | Claude Code / Codex | Copilot (VS Code) | Cursor / Antigravity |
|-------|------|---------------------|--------------------|-----------------------|
| `neeve-guide` | Setup help, plus "which skill/agent do I use for X" triage | auto-triggers / `/agent` | pick from agent picker | auto-triggers (as a skill) |
| `to-prd` | Turns a problem into an enterprise-SaaS PRD, led by a security/ops-in-CRE-OT journey | auto-triggers / `/agent` | pick from agent picker | auto-triggers (as a skill) |
| `to-erd` | Turns a PRD into a compliance-aware work-item breakdown | auto-triggers / `/agent` | pick from agent picker | auto-triggers (as a skill) |
| `repo-guide` | Knows this specific repo — role, stack, structure/style, local dev, deploy | auto-triggers / `/agent` | pick from agent picker | auto-triggers (as a skill) |
| `neeve-reviewer` | Ad hoc Neeve-flavored code/spec review, for any repo | auto-triggers / `/agent` | pick from agent picker | auto-triggers (as a skill) |
| `neeve-security-partner` | Dedicated adversarial security pass — OWASP, pentest mindset, multi-tenancy | auto-triggers / `/agent` | pick from agent picker | auto-triggers (as a skill) |
| `neeve-pm-partner` | PM-shaped review before/alongside `to-prd`/`to-spec` — named outcome, enterprise requirements, rollout story | auto-triggers / `/agent` | pick from agent picker | auto-triggers (as a skill) |
| `neeve-design-partner` | DLS fidelity, accessibility, and failure-state design review | auto-triggers / `/agent` | pick from agent picker | auto-triggers (as a skill) |

## Prompt Files (slash commands)

If your editor surfaces `.github/prompts/*.prompt.md` as slash commands, the
same seven workflows are available as `/to-spec`, `/implement-spec`,
`/code-review`, `/repo-ask`, `/repo-intel`, `/neeve-dls`, `/debug-trace` —
thin wrappers around the skills above, useful where automatic skill-matching
doesn't trigger (e.g. inline chat).
