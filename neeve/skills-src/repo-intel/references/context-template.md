# CONTEXT.md Template

Use this structure when writing `CONTEXT.md`. Omit sections that have no grounded content —
write `Not found — add manually.` rather than leaving them blank or inventing content.
Cite file paths for every non-obvious claim.

---

```markdown
# [Project Name] — Context

> One-sentence description of what this service/app does and who consumes it.

## Stack

| Concern | Choice | Version |
|---|---|---|
| Language | | |
| Runtime | | |
| Framework | | |
| Database | | |
| Cache | | |
| Message broker | | |
| Container / deploy | | |

## Repository Layout

```
<top-level directory tree, 2 levels deep>
```

| Path | Purpose |
|---|---|
| `src/` or `app/` | ... |
| `tests/` | ... |
| `docs/` | ... |
| `infra/` or `helm/` | ... |

## Domain Concepts

Key terms and entities this service owns or operates on. Define each in one sentence.

| Term | Definition |
|---|---|
| | |

## Module Map

One row per significant module or bounded context.

| Module | Path | Purpose | Key dependencies |
|---|---|---|---|
| | | | |

## API Contracts

### REST / HTTP

Base URL: `...`
Auth: `...`

| Method | Path | Purpose | Auth required |
|---|---|---|---|
| | | | |

OpenAPI spec: `path/to/openapi.yaml` or `Not found — routes read from source`.

### Events / Async

| Subject / Topic | Direction | Payload type | Producer | Consumer(s) |
|---|---|---|---|---|
| | | | | |

### Internal Interfaces

Key TypeScript interfaces, Pydantic models, Go interfaces, or Protocols that form the
internal contract boundary.

| Name | File | Purpose |
|---|---|---|
| | | |

## Database Schema

| Table / Collection | Key columns | Relationships | Notes |
|---|---|---|---|
| | | | |

Migration tool: `...`
Run migrations: `...`

## Patterns

### Error Handling
[How errors are caught, mapped, and returned. Cite file.]

### Authentication / Authorization
[Middleware name, token type, where authz decisions are made. Cite file.]

### Dependency Injection
[Container or manual wiring approach. Cite file.]

### Async / Background Work
[Queue workers, async tasks, event handlers. Cite files.]

### Naming Conventions
- Files: [snake_case / kebab-case / PascalCase]
- Classes: [PascalCase]
- Functions / methods: [snake_case / camelCase]
- Constants: [UPPER_SNAKE / SCREAMING_SNAKE]
- DB columns: [snake_case]

### Logging
[Structured or unstructured. What is logged at each level. Cite config.]

### Testing
[Mock vs. real dependencies. Fixture approach. Integration test setup. Cite config.]

## Quality Tooling

| Tool | Purpose | Command |
|---|---|---|
| Linter | | `...` |
| Formatter | | `...` |
| Type checker | | `...` |
| Tests | | `...` |
| Coverage | | `...` |
| Build | | `...` |
| Code generation | | `...` (if any) |

Config files: [list linter/formatter config paths]

## Local Development

### Prerequisites
- [e.g. Docker, Node 20, Python 3.11, Go 1.22]

### Setup
```bash
# 1. Clone and install
...
# 2. Copy env template
cp .env.example .env
# 3. Start dependencies
docker-compose up -d
# 4. Run migrations / seed
...
# 5. Start the app
...
```

### Required Environment Variables

| Variable | Purpose | Example |
|---|---|---|
| | | |

## Architectural Decisions

Key decisions visible in the code. For full context see `docs/adr/`.

| Decision | Rationale (brief) | ADR |
|---|---|---|
| | | |

## Known Gaps / Follow-on

- [Anything marked [inferred] or [unknown] during the scan]
- [Sections that need owner input]
```
