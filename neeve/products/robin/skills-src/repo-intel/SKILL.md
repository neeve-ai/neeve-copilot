---
name: repo-intel
description: >
  Scan a project and produce a living knowledge base that any LLM or human can use to build,
  fix, or perform tasks without prior context. Trigger on: "map this repo", "document this
  project", "build a knowledge base", "onboard me to this codebase", "document the patterns",
  "what does this project do", "generate CONTEXT.md", "document the architecture", or any
  request to understand, document, or onboard a codebase. Produces CONTEXT.md, README updates,
  ADR stubs, and spec stubs derived from actual code — never invented.
---

# Repo Intel

This skill scans a project and writes structured knowledge that makes the codebase legible to
any LLM or human arriving cold. The output is derived from the actual code — no invented
patterns, no guessed decisions.

The primary deliverable is a `CONTEXT.md` at the project root that acts as the persistent
knowledge anchor for all future work in the repo.

## What Good Output Looks Like

A good `CONTEXT.md` lets anyone answer these questions without reading source files:

- What does this service/app do and who consumes it?
- What is the tech stack and runtime?
- How is the code organized (modules, layers, boundaries)?
- What are the key domain concepts and their relationships?
- What are the API/event contracts this service owns or depends on?
- How do I run, build, lint, and test this project locally?
- What patterns does the codebase enforce (error handling, auth, DI, async)?
- What architectural decisions have been made and why?
- What is out of scope or deliberately deferred?
- Where are this service's trust boundaries (auth entry points, tenant-scoping,
  external network calls, secrets), and what would the production consequence be
  if one of them were misconfigured?
- What security/compliance gaps are known and unaddressed (missing audit log,
  missing rate limit, a disabled or absent CI security gate) — named explicitly,
  not left for the reader to discover?

If the output cannot answer these, it is not done.

## Workflow

### Phase 0 — Scope Check

Before scanning, confirm with the user:

1. The root directory to scan (default: current working directory).
2. Whether to write files or only report findings (default: write).
3. Whether to include ADR stubs and spec stubs or only `CONTEXT.md` (default: all).

### Phase 1 — Stack and Entry Point Discovery

Identify the project's foundation without reading every file:

- **Language and runtime:** check `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`,
  `pom.xml`, `build.gradle`, `.tool-versions`, `.nvmrc`, `.python-version`.
- **Framework:** check imports/dependencies for FastAPI, Express, Django, NestJS, Next.js,
  Spring, Gin, etc.
- **Entry points:** `main.py`, `app.py`, `index.ts`, `cmd/`, `server.ts`, `wsgi.py`.
- **Containerization:** `Dockerfile`, `docker-compose.yml`, Helm charts, `k8s/`.
- **CI/CD:** `.github/workflows/`, `bitbucket-pipelines.yml`, `Makefile`, `.gitlab-ci.yml`.
- **Monorepo signals:** `pnpm-workspace.yaml`, `nx.json`, `turbo.json`, `packages/`, `apps/`,
  `services/`.

Record: language, runtime version, framework, monorepo or single-repo, deployment target.

### Phase 2 — Module and Service Map

Walk the top-level directory structure and classify each significant directory:

- **Domain modules:** feature areas or bounded contexts (`auth/`, `billing/`, `orgs/`,
  `notifications/`).
- **Infrastructure layer:** database, cache, message broker, external clients (`db/`,
  `redis/`, `nats/`, `infrastructure/`).
- **API layer:** routes, controllers, resolvers, handlers (`routes/`, `api/`, `controllers/`,
  `graphql/`).
- **Service / use-case layer:** business logic (`services/`, `usecases/`, `domain/`).
- **Shared utilities:** helpers, types, constants (`utils/`, `lib/`, `shared/`, `common/`).
- **Configuration:** env loading, settings (`config/`, `settings.py`, `env.ts`).
- **Tests:** unit, integration, e2e locations and patterns.

For each module, record: purpose, key files, owned domain concepts, external dependencies.

### Phase 3 — Contract Extraction

Read actual interface definitions — do not invent them:

#### OpenAPI / REST
- Locate OpenAPI spec files (`openapi.yaml`, `swagger.json`, auto-generated `/docs`).
- If no spec file exists, read route definitions and extract: method, path, request shape,
  response shape, auth requirement.
- Record: owned endpoints, request/response schemas, auth model, error response shapes.

#### Events / Async
- Locate NATS subjects, Kafka topics, SQS queues, pub/sub channels.
- Read publisher and subscriber code to extract: event name, payload schema, producer,
  consumer(s), ordering/idempotency guarantees.

#### Internal interfaces
- Read TypeScript `interface`/`type` exports, Python `Protocol`/`TypedDict`/Pydantic models,
  Go interfaces, Java interfaces.
- Record: name, fields, owning module, consumers.

#### Database schema
- Read ORM models (`models.py`, `schema.prisma`, `*.entity.ts`, migration files).
- Record: tables/collections, key columns, relationships, constraints, indexes.

### Phase 4 — Pattern Extraction

Read enough source to identify the patterns the codebase enforces. Check at least 3
representative files per pattern area:

- **Error handling:** custom exception classes, error middleware, HTTP error mapping.
- **Authentication / authorization:** middleware, decorators, JWT/session approach, RBAC model.
- **Dependency injection:** constructor DI, container wiring, provider patterns.
- **Async patterns:** async/await, background tasks, queue workers, event loops.
- **Naming conventions:** file names, class names, function names, variable names — note
  the dominant style (snake_case, camelCase, PascalCase per context).
- **Logging:** structured vs. unstructured, log levels in use, what is and isn't logged.
- **Testing patterns:** mock style, fixture approach, integration test setup, factory patterns.
- **Configuration:** how env vars are loaded, validated, and accessed.

Record the pattern as a rule: "The codebase does X by Y. Example: `path/to/file.py:42`."

### Phase 5 — Quality Tooling

Read the actual config files — do not guess:

#### Linter
- Python: `pyproject.toml` (`[tool.ruff]`, `[tool.flake8]`), `.flake8`, `setup.cfg`.
- TypeScript/JS: `.eslintrc.*`, `eslint.config.*`, `.prettierrc`.
- Go: `golangci.yml`.
- Record: linter name, key rules, how to run (`make lint`, `npm run lint`, `ruff check .`).

#### Formatter
- Record: formatter name and how to run.

#### Tests
- Read test runner config: `pytest.ini`, `jest.config.*`, `vitest.config.*`, `go test`.
- Record: test command, coverage command, test directory layout, whether tests require
  external services (DB, Redis, NATS) or use mocks.

#### Build
- Record: how to build (`npm run build`, `make build`, `go build ./...`), output artifacts,
  any code generation steps that must run first (`npm run generate`, `make proto`).

#### Local dev
- Record: how to start locally, required env vars, seed/migration commands, any
  `docker-compose up` prerequisites.

### Phase 6 — Write Outputs

Write only what is grounded in Phase 1–5 findings. Do not invent sections.

#### 6a — CONTEXT.md

Write `CONTEXT.md` at the project root using
[`references/context-template.md`](references/context-template.md) as the structural guide.

Rules:
- Every claim must be traceable to a file or config read in Phases 1–5.
- Cite file paths for key decisions: "Auth uses JWT — see `app/middleware/auth.py:12`."
- Mark anything inferred (not read) as `[inferred]` so a reader knows to verify.
- If a section has no grounded content, write `Not found — add manually.` rather than
  inventing placeholder text.

#### 6b — README gaps

Read the existing `README.md`. Add or update only sections that are missing or factually wrong
based on Phase 5 findings:
- Getting started / local setup
- How to run tests
- How to lint / format
- Environment variable reference (list required vars, no secret values)

Do not rewrite sections that are accurate. Append a `<!-- repo-intel: updated -->` comment on
changed sections so the change is traceable.

#### 6c — ADR stubs (if requested)

For each significant architectural decision found during Phases 1–4 that has no existing ADR:
- Create `docs/adr/ADR-NNNN-<slug>.md` stubs using the format in
  [`references/adr-stub-template.md`](references/adr-stub-template.md).
- Only stub decisions that are visible in the code (a pattern that was clearly chosen, not
  an absent pattern). Do not fabricate decisions.
- Pre-fill what is known from the code; leave `[unknown — needs author input]` for context
  that cannot be derived from reading.

#### 6d — Spec stubs (if requested)

For each service, module, or API surface that has no spec or doc:
- Create a minimal spec stub at `specs/SPEC-<module>.md` using the concise work-item
  structure from the `to-spec` skill (Summary, In Scope, Owned Interfaces, Functional
  Requirements) — pre-filled from Phase 3 contract extraction.
- Mark every section `[derived from code — verify with owner]`.

### Phase 7 — Sign-off Report

After writing all outputs, emit a compact report:

```
## Repo Intel Sign-off

| Area | Status | Key finding |
|---|---|---|
| Stack / runtime | ✅ / ⚠️ | [e.g. Python 3.11, FastAPI] |
| Module map | ✅ / ⚠️ | [N modules identified] |
| OpenAPI / REST contracts | ✅ / ⚠️ / N/A | |
| Event / async contracts | ✅ / ⚠️ / N/A | |
| Database schema | ✅ / ⚠️ / N/A | |
| Internal interfaces | ✅ / ⚠️ / N/A | |
| Error handling pattern | ✅ / ⚠️ | |
| Auth / authz pattern | ✅ / ⚠️ / N/A | |
| Trust boundaries / tenant-scoping identified | ✅ / ⚠️ / N/A | |
| Security CI gates present (secrets/SAST/SCA scanning) | ✅ / ⚠️ / ❌ | |
| DI / wiring pattern | ✅ / ⚠️ / N/A | |
| Naming conventions | ✅ / ⚠️ | |
| Linter — command confirmed | ✅ / ⚠️ / N/A | |
| Formatter — command confirmed | ✅ / ⚠️ / N/A | |
| Test command confirmed | ✅ / ⚠️ | |
| Build command confirmed | ✅ / ⚠️ | |
| Local dev setup documented | ✅ / ⚠️ | |
| CONTEXT.md written | ✅ / ❌ | |
| README gaps patched | ✅ / ❌ / N/A | |
| ADR stubs written | ✅ / ❌ / N/A | |
| Spec stubs written | ✅ / ❌ / N/A | |

Gaps requiring human input:
- [List anything marked [inferred] or [unknown] in the outputs]

Security/production gaps found (or "none identified — verified via [what was checked]"):
- [A missing security CI gate, an undocumented trust boundary, a tenant-scoping
  pattern that couldn't be confirmed — named explicitly, per the `code-review`
  skill's `references/security.md` Security Gates table where applicable]
```

A ⚠️ means the area was found but is incomplete (e.g. partial schema, no spec file — routes
read instead). An ❌ means not found and not written. Any gap listed must be called out
explicitly so the owner knows what to fill in manually. The security/production gaps line
must never be left blank by omission — state what was checked if nothing was found.

## Quality Rules

- Never invent a pattern, contract, or decision. If it is not in the code, mark it absent.
- Never copy-paste large blocks of source code into CONTEXT.md — summarize and cite.
- Prefer one accurate sentence over three vague ones.
- If a module's purpose is unclear from reading it, say so rather than guessing.
- CONTEXT.md should be readable in under 10 minutes. If it exceeds ~400 lines, split by
  domain module into `docs/context/` and keep a short index in `CONTEXT.md`.
- After writing, re-read CONTEXT.md as if you are arriving at the repo for the first time.
  If you cannot answer all nine questions from "What Good Output Looks Like" above, the
  output is not done.

## Anti-Patterns

Do not:
- Invent architectural decisions not visible in the code.
- Write generic boilerplate sections ("This service follows clean architecture...") without
  tracing it to actual file structure.
- Document every file — map modules and boundaries, not individual functions.
- Skip linter/test/build commands because they seem obvious.
- Leave a section blank — always write `Not found — add manually.` so the gap is explicit.
- Write the sign-off before all outputs are written.
- Claim a contract is "standard REST" without reading the actual routes.

---

## Skill Chain

`repo-intel` produces the broad knowledge base. Use it when arriving at an unfamiliar
codebase before any other skill, or when `repo-ask` reveals that foundational context
is missing across multiple areas.

| Situation | Next skill |
|---|---|
| A specific question arises during or after the scan | → `repo-ask` (targeted trace) |
| CONTEXT.md reveals undocumented features that need specs | → `to-spec` |
| CONTEXT.md reveals a bug or broken contract | → `repo-ask` first, then `to-spec` |
| Codebase is fully mapped and a task is ready to implement | → `implement-spec` |

**Feeds into:** `repo-ask`, `to-spec`, `implement-spec`
**Fed by:** nothing — run this first on an unfamiliar repo

Load `references/quality-gates.md` when documenting the linter, test, and build commands
in Phase 5 — use it to verify the project meets the production standard.
