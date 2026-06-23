# Neeve Engineering Skills

Skills that work identically across every agent on the team.

| Skill | What it does |
|-------|-------------|
| `repo-intel` | Full codebase scan → CONTEXT.md, README gaps, ADR stubs, spec stubs |
| `repo-ask` | Targeted question-driven code trace — clarifies intent, code is always source of truth |
| `to-spec` | Turns a feature, bug, or ADR into a Neeve-style spec with handoff for `implement-spec` |
| `implement-spec` | Implements a spec task: context-first, reuse-first, typed contracts, behaviour tests |
| `code-review` | SMART production review: ADR/spec alignment, contracts, correctness, security, Helm |
| `neeve-dls` | Pixel-perfect changes to the `dls-neeve` design system and shared `@neeve/fonts` package |

### Skill chain

```
repo-ask / repo-intel     ← understand the codebase first
        ↓
     to-spec              ← turn the problem into an approved spec
        ↓
  implement-spec          ← build it; all 7 quality gates must pass
        ↓
   code-review            ← final quality checkpoint; loops back if findings require changes
```

`neeve-dls` sits alongside `implement-spec` for any UI/DLS surface; always followed by `code-review`.

### Quality gates (enforced by `implement-spec` and `code-review`)

Every implementation must pass all 7 gates before it is done:
linter (zero warnings) · strict type checker (zero errors) · unit tests (≥95% coverage) ·
integration tests (primary flow) · scale/N+1 check · security (inputs, auth, secrets, deps) ·
code review (no 🔴/🟠 unresolved).

---

## Supported Agents

The SKILL.md format is an open standard. One set of files, every agent.

| Agent | Works? | Notes |
|-------|--------|-------|
| Claude Code (terminal) | ✅ | Primary surface |
| VS Code — Claude extension | ✅ | Same skills as terminal |
| VS Code — GitHub Copilot | ✅ | Agent mode required |
| Cursor | ✅ | Chat panel |
| Antigravity | ✅ | |
| Codex CLI | ✅ | Uses `$skill-name` instead of `/skill-name` |

---

## Setup

### Fastest path (recommended)

From the root of the `neeve-copilot` repo checkout:

```bash
bash sync_skills.sh
```

This pulls the latest from the repo and installs all skills for every agent on your machine.
Run it any time to pick up changes. See the root `README.md` for the one-liner alias.

### Manual install

If you need to install without pulling (e.g. offline, or from a specific state):

### What you need

```
neeve-skills/
  install.sh       ← this installer
  AGENTS.md        ← commit to every repo (read by Copilot, Codex, Antigravity)
  README.md        ← this file
  skills-src/      ← canonical skill sources when working from a repo checkout
```

If you do not want a full checkout, download the latest GitHub release bundle. It includes
`install.sh`, `AGENTS.md`, `README.md`, and prebuilt skill zip assets.

`install.sh` resolves skill archives in this order:

1. bundled `zips/` next to the installer
2. local `dist/zips/` built from `skills-src`
3. a fresh rebuild from `skills-src` into `dist/zips/`

### Step 1 — Run the installer

**Auto-detect what's installed on your machine:**
```bash
bash install.sh
```

**Specific agents:**
```bash
bash install.sh --claude-code --codex --cursor
```

**All agents at once:**
```bash
bash install.sh --all
```

**Global install + project-scoped (for team sharing via git):**
```bash
bash install.sh --all --project /path/to/robin-ai
```

### Step 2 — Add AGENTS.md to your repos

```bash
cp AGENTS.md /path/to/robin-ai/AGENTS.md
git add AGENTS.md
git commit -m "chore: add agent instructions"
```

This file is read as always-on context by Copilot, Codex, and Antigravity.
Claude Code reads `CLAUDE.md` — see per-agent notes below.

### Step 3 — Commit project-scoped skills (optional but recommended)

If you ran `--project`, commit what was installed so every team member gets
skills automatically on `git clone`:

```bash
cd /path/to/robin-ai
git add .claude/skills/ .github/skills/ .agents/skills/ .cursor/skills/
git commit -m "chore: add Neeve engineering skills"
```

---

## Where skills install

| Agent | Global (personal, all projects) | Project-scoped (repo, shared) |
|-------|--------------------------------|-------------------------------|
| Claude Code | `~/.claude/skills/` | `.claude/skills/` |
| GitHub Copilot | `~/.copilot/skills/` | `.github/skills/` |
| Cursor | `~/.cursor/skills/` | `.cursor/skills/` |
| Codex CLI | `~/.codex/skills/` | `.agents/skills/` |
| Antigravity | `~/.gemini/antigravity/skills/` | `.agents/skills/` |

**Global** = installed once per machine, available in all projects.
**Project-scoped** = committed to git, shared automatically on clone.

Recommended: install globally on each machine + commit project-scoped for new joiners.

---

## How skills trigger

Skills load **automatically** when the agent matches your request to a skill description.

| What you say | Skill loaded |
|-------------|-------------|
| "map this repo", "document this project", "generate CONTEXT.md" | `repo-intel` |
| "onboard me to this codebase", "what does this service do" | `repo-intel` |
| "how does X work", "why does X fail", "trace X", "where is X defined" | `repo-ask` |
| "what happens when X is called", "show me how X connects to Y" | `repo-ask` |
| "spec this feature", "turn this bug into a work item" | `to-spec` |
| "break this ADR into tasks", "write requirements for X" | `to-spec` |
| "implement task 3", "build this from the spec" | `implement-spec` |
| "write the code for this work item" | `implement-spec` |
| "review this PR for production readiness" | `code-review` |
| "audit these changes against the spec", "review my Helm changes" | `code-review` |
| "update this DLS component", "fix this UI to match the design" | `neeve-dls` |

**Manual invoke:**
```
Claude Code / Copilot / Cursor / Antigravity:
  /repo-intel  /repo-ask  /to-spec  /implement-spec  /code-review  /neeve-dls

Codex CLI:
  $repo-intel  $repo-ask  $to-spec  $implement-spec  $code-review  $neeve-dls
```

---

## Always-on context per agent

Skills are on-demand. For always-on project context, use the right file:

| Agent | Always-on file | What to put in it |
|-------|---------------|-------------------|
| Claude Code | `CLAUDE.md` (root or `.claude/`) | Stack, test commands, arch constraints |
| GitHub Copilot | `.github/copilot-instructions.md` | Same |
| Cursor | `.cursorrules` | Same |
| Codex · Antigravity | `AGENTS.md` | Engineering principles (included) |
| All agents | `AGENTS.md` | Copilot, Codex, Antigravity all read this |

A minimal `CLAUDE.md` for each repo:

```markdown
# [Repo] — Claude Code Context

## Stack
- Python 3.11 / FastAPI / PostgreSQL / NATS JetStream
- Deployed via robin-helm on Kubernetes

## Repo layout
- domain/        entities, value objects, protocols — no framework imports
- application/   use cases, orchestration
- infrastructure/ repositories, ORM, NATS/HTTP clients
- api/           FastAPI routers — thin glue only

## Test
pytest -x -v
pytest tests/unit/test_foo.py -v
pytest --cov=app --cov-fail-under=95

## Lint
mypy app/ --strict && ruff check app/ tests/

## Do not modify without discussion
- alembic/versions/    migration files are append-only
- app/domain/events/   event contract shared with downstream services
```

---

## Agent-specific notes

### Claude Code + VS Code (Claude extension)
- Skills in `~/.claude/skills/` load in every project
- Verify: `/skills`
- Per-project context: `CLAUDE.md` at repo root or `.claude/CLAUDE.md`

### GitHub Copilot (VS Code agent mode)
- Skills in `~/.copilot/skills/` load globally
- Skills in `.github/skills/` load for the repo — commit these
- Always-on context: `.github/copilot-instructions.md`
- Verify: `/skills` in Copilot Chat (agent mode only)
- Copilot reads `AGENTS.md` at repo root automatically

### Cursor
- Skills in `~/.cursor/skills/` load globally
- Skills in `.cursor/skills/` load per-project
- Always-on context: `.cursorrules` at repo root
- Verify: `/skills` in Cursor Chat

### Codex CLI
- Skills in `~/.codex/skills/` or `~/.agents/skills/` load globally
- Skills in `.agents/skills/` load per-project
- Codex reads `AGENTS.md` at repo root automatically
- Verify: `$skills`
- Invoke: `$code-review`, `$to-spec`, `$implement-spec`

### Antigravity (Google)
- Skills in `~/.gemini/antigravity/skills/` load globally
- Skills in `.agents/skills/` load per-project (shared with Codex)
- Antigravity reads `AGENTS.md` at repo root automatically
- Verify: `@skills`

---

## Troubleshooting

**Skill not showing up after install:**
Restart the agent / start a new session. Skills are loaded at session start.

**Wrong nesting after manual unzip:**
The correct path is `~/.claude/skills/code-review/SKILL.md`, not
`~/.claude/skills/code-review/code-review/SKILL.md`. The installer handles
this — if you unzipped manually, check the depth with:
```bash
ls ~/.claude/skills/code-review/
# Should show: SKILL.md  agents/  references/
```

**Copilot not picking up `.github/skills/`:**
Ensure you are in **agent mode** (not inline chat or quick fix). Copilot agent
mode is where skill discovery runs.

**Antigravity path missing:**
```bash
mkdir -p ~/.gemini/antigravity/skills
```
Then re-run the installer.

**Update skills:**
Re-run the installer — it replaces old versions, safe to run any time:
```bash
bash install.sh --all
```

---

## Maintainer Workflow (skills-src → release zips)

This repo keeps editable skill sources in:

`neeve/products/robin/skills-src/`

Generated archives are written to:

`neeve/products/robin/dist/zips/`

Any top-level folder in `skills-src/` is treated as a skill package and must contain `SKILL.md`.

### Source of truth

`skills-src` is canonical. Edit files there, then rebuild zips locally when needed.

### Sync commands

```bash
# Pull latest + reinstall all skills for every agent (recommended daily driver)
bash sync_skills.sh                          # from repo root

# Verify every skill packages cleanly into a release zip
neeve/products/robin/scripts/skills_sync.sh check

# Build zips from skills-src into neeve/products/robin/dist/zips/
neeve/products/robin/scripts/skills_sync.sh pack
```

### CI enforcement

Validation CI runs `skills_sync.sh check` on every push and pull request.
If a skill cannot be packaged into a valid release archive, CI fails and merge is blocked.

### GitHub Releases

Release archives are generated by GitHub Actions, not stored in git.

Push to `main`:

- updates the moving prerelease tagged `robin-skills-latest`
- refreshes the downloadable zip assets on that prerelease
- reruns packaging and installer smoke checks before publishing

Push a tag that matches `robin-skills-v*`:

- creates or updates a versioned GitHub Release
- publishes the same downloadable zip assets on that versioned release
- reruns packaging and installer smoke checks before publishing

Both release paths build:

- `repo-intel.zip`
- `repo-ask.zip`
- `code-review.zip`
- `to-spec.zip`
- `implement-spec.zip`
- `neeve-dls.zip`
- `robin-skills-bundle.zip` containing `install.sh`, `AGENTS.md`, `README.md`, and all skill zips
