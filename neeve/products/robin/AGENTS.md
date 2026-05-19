# Neeve Engineering — Agent Instructions

Read by: GitHub Copilot · OpenAI Codex · Google Antigravity · Claude Code

Place at the repo root as `AGENTS.md`. This is always-on context — every session,
every agent. Skills layer on top for task-specific depth.

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

---

## Skills Available

These skills are installed per-repo and globally. They trigger automatically
when the description matches your request, or invoke manually.

| Skill | Triggers when you... | Manual invoke |
|-------|---------------------|---------------|
| `code-review` | Ask to review, audit, or check production readiness | `/code-review` / `$code-review` |
| `to-spec` | Ask to write a spec, plan a feature, or break into tasks | `/to-spec` / `$to-spec` |
| `implement-spec` | Ask to implement a task, build from a spec, or write code | `/implement-spec` / `$implement-spec` |

The three skills form a pipeline: `to-spec` → `implement-spec` → `code-review`.
