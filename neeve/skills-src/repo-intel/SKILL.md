---
name: repo-intel
description: >
  Scan a project and produce its OKF book — introduction.md, index.md, appendix.md at the
  repo root — the living, committed knowledge base any LLM or human uses to build, fix, or
  perform tasks without prior context. Trigger on: "map this repo", "document this project",
  "build a knowledge base", "onboard me to this codebase", "fill the OKF book", "refresh the
  repo book", "repo-intel --refresh", "document the architecture", or any request to
  understand, document, or onboard a codebase. Also produces README updates, ADR stubs, and
  spec stubs — all derived from actual code, never invented.
---

# Repo Intel

This skill scans a project and writes structured knowledge that makes the codebase legible to
any LLM or human arriving cold. The output is derived from the actual code — no invented
patterns, no guessed decisions.

The primary deliverable is the **OKF book** — three committed files at the repo root,
following the book analogy for maintaining context efficiently (Layer 02 of the 4-Layer
Context stack, see neeve-copilot's `neeve/README.md`):

| File | Role | Analogy |
|---|---|---|
| `introduction.md` | Contextual README *for agents*: stack & versions, how this repo wires into the product (NATS/HTTP/MCP, OpenAPI contract if a backend), make targets, docker/local-dev, deploy path. Small — always read first. | A book's introduction |
| `index.md` | Functional areas mapped to where they live ("Auth → `src/auth/**`, entrypoint `src/auth/middleware.ts`, see `appendix.md#AuthService`") so an agent jumps straight to the right place instead of grepping cold. | Table of contents |
| `appendix.md` | Every public method/class with its **purpose**, **dependencies** (calls / called by), and **impact if changed** (blast radius). The expensive, highest-value-when-correct file. | The appendix |

The scaffolds (with `TODO(repo-intel)` markers) are created by neeve-copilot's
`neeve/init-repo.sh`, which also installs the `.githooks/pre-commit` context-sync hook.
This skill fills and refreshes them from a real scan. If the book files don't exist yet
and init-repo.sh hasn't been run, tell the user to run it first (it also wires the
freshness hook) — or create the three files directly if they decline.

**Freshness contract:** the committed pre-commit hook deterministically flags drift
(manifest-hash on `introduction.md`, structural diff on `index.md`, public-symbol diff on
`appendix.md`). This skill is the *narrative* refresh the hook points at — after any
refresh, re-stamp the manifest hash: `python3 .githooks/pre-commit --stamp`.

## What Good Output Looks Like

A good book lets anyone answer these questions without reading source files:

- What does this service/app do and who consumes it?
- What is the tech stack and runtime?
- How is the code organized (modules, layers, boundaries)?
- What are the key domain concepts and their relationships?
- What are the API/event contracts this service owns or depends on?
- How do I run, build, lint, and test this project locally — including any
  environment quirk (a `.venv`/virtualenv that needs activating, a
  `Makefile` target that wraps the raw command) that a bare command alone
  would miss?
- What does this repo's actual CI workflow (`.github/workflows/*.yml` or
  equivalent) enforce, and does that match the documented local commands?
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
3. Whether to include ADR stubs and spec stubs or only the OKF book (default: all).

### Phase 1 — Stack and Entry Point Discovery

**First, read the repo's own OKF book if it exists** (`introduction.md`,
`index.md`, `appendix.md`). Cross-check what follows against those repo-level
facts rather than treating the scan as if nothing were already documented.
If the code contradicts the existing OKF book, name that as a finding and
update the repo-level book directly as part of the refresh.

Identify the project's foundation without reading every file:

- **Language and runtime:** check `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`,
  `pom.xml`, `build.gradle`, `.tool-versions`, `.nvmrc`, `.python-version`.
- **Framework:** check imports/dependencies for FastAPI, Express, Django, NestJS, Next.js,
  Spring, Gin, etc.
- **Entry points:** `main.py`, `app.py`, `index.ts`, `cmd/`, `server.ts`, `wsgi.py`.
- **Containerization:** `Dockerfile`, `docker-compose.yml`, Helm charts, `k8s/`.
- **CI:** `.github/workflows/*.yml` or equivalent — what it actually lints/tests/scans.
- **Environment quirks:** a Python virtualenv (`.venv`, `Pipfile`, `poetry.lock`) that
  needs activating, or a `Makefile` that wraps the real test/lint/run commands — note
  these explicitly rather than letting `introduction.md` imply a bare command is sufficient.
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

If a pattern's actual behavior depends on an unfamiliar third-party library
or framework (e.g. a DI container's resolution order, an ORM's session
lifecycle), invoke `debug-trace` to ground that library's real, version-
specific behavior rather than documenting a remembered-but-unverified belief
about it as a "pattern" — a wrong pattern in the book propagates to every
future skill/agent that reads it. Note the **Depth check** line
(`debug-trace`'s Disclosure Requirement) next to that pattern in the book
so a later reader knows whether it was grounded.

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

#### 6a — The OKF book (`introduction.md`, `index.md`, `appendix.md`)

Fill (or refresh) the three book files at the project root. `introduction.md`,
`index.md`, and `appendix.md` follow the table formats the init-repo.sh
scaffolds establish and the content rules below — there is no separate
template file; the scaffold plus these rules is the structural guide.

- `introduction.md` — Phases 1 + 5 findings: role in the product (cross-checked against
  the repo's committed OKF book (`introduction.md`, `index.md`, `appendix.md`), stack/runtime, how it wires into the product
  (Phase 3's owned/consumed contracts, summarized with pointers into `index.md`), every
  make target, local-dev spin-up including environment quirks, deploy path. Keep it
  small — it's the always-read-first file, not the encyclopedia.
- `index.md` — Phase 2's module map, organized by functional area/domain (not a raw
  directory listing): area → path glob → entry-point file → `appendix.md#Anchor` for the
  deep dive.
- `appendix.md` — Phases 3 + 4 at symbol level: one section per module, a table of
  public symbols with purpose, dependencies (what it calls / what calls it — traced, not
  guessed), and impact-if-changed (which modules or downstream services break). Resolve
  every `TODO(purpose)` the pre-commit hook has flagged. This is the expensive file; for
  a large repo, prioritize modules on trust boundaries and shared contracts first and
  mark the rest `TODO(repo-intel): not yet scanned` — an honest partial appendix beats a
  vague complete one.

Rules (all three files):
- Every claim must be traceable to a file or config read in Phases 1–5.
- Cite file paths for key decisions: "Auth uses JWT — see `app/middleware/auth.py:12`."
- Mark anything inferred (not read) as `[inferred]` so a reader knows to verify.
- If a section has no grounded content, write `Not found — add manually.` rather than
  inventing placeholder text.
- After writing, re-stamp: `python3 .githooks/pre-commit --stamp` (updates
  `introduction.md`'s manifest-hash so the hook stops flagging staleness), then run
  `python3 .githooks/pre-commit --all` and confirm it exits clean.
- If this repo predates the book and has a legacy `CONTEXT.md`, migrate its
  still-accurate content into the three files and delete it — two competing knowledge
  anchors is exactly the drift this structure exists to prevent.

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
| introduction.md written/refreshed | ✅ / ❌ | |
| index.md written/refreshed | ✅ / ❌ | |
| appendix.md written/refreshed (TODO(purpose) count after: N) | ✅ / ⚠️ / ❌ | |
| manifest-hash re-stamped + hook --all exits clean | ✅ / ❌ | |
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
- Never copy-paste large blocks of source code into the book — summarize and cite.
- Prefer one accurate sentence over three vague ones.
- If a module's purpose is unclear from reading it, say so rather than guessing.
- `introduction.md` should be readable in under 5 minutes; `index.md` scannable at a
  glance. Depth lives in `appendix.md` — that's the file allowed to be long, organized
  by module anchors so nobody reads it linearly.
- After writing, re-read the book as if you are arriving at the repo for the first time.
  If you cannot answer all the questions from "What Good Output Looks Like" above, the
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
| The book reveals undocumented features that need specs | → `to-spec` |
| The book reveals a bug or broken contract | → `repo-ask` first, then `to-spec` |
| Codebase is fully mapped and a task is ready to implement | → `implement-spec` |

**Feeds into:** `repo-ask`, `to-spec`, `implement-spec`
**Fed by:** nothing — run this first on an unfamiliar repo

Load `references/quality-gates.md` when documenting the linter, test, and build commands
in Phase 5 — use it to verify the project meets the production standard.
