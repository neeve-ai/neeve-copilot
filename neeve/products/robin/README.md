# Neeve Engineering Skills

Three skills that work identically across every agent on the team.

| Skill | What it does |
|-------|-------------|
| `code-review` | SMART production review: ADR/spec alignment, contracts, correctness, security, Helm |
| `to-spec` | Turns a feature, bug, or ADR into a Neeve-style spec with handoff for `implement-spec` |
| `implement-spec` | Implements a spec task: context-first, reuse-first, typed contracts, behaviour tests |

The three form a pipeline: **`to-spec` → `implement-spec` → `code-review`**

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

### What you need

```
neeve-skills/
  install.sh       ← this installer
  AGENTS.md        ← commit to every repo (read by Copilot, Codex, Antigravity)
  README.md        ← this file
  zips/
    code-review.zip
    to-spec.zip
    implement-spec.zip
```

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
| "review this PR for production readiness" | `code-review` |
| "audit these changes against the spec" | `code-review` |
| "review my Helm changes" | `code-review` |
| "spec this feature" | `to-spec` |
| "turn this bug into a work item" | `to-spec` |
| "break this ADR into tasks" | `to-spec` |
| "implement task 3" | `implement-spec` |
| "build the outbox worker from the spec" | `implement-spec` |
| "write the code for this work item" | `implement-spec` |

**Manual invoke:**
```
Claude Code / Copilot / Cursor / Antigravity:   /code-review  /to-spec  /implement-spec
Codex CLI:                                       $code-review  $to-spec  $implement-spec
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

## Maintainer Workflow (skills-src ↔ zips)

This repo keeps editable skill sources in:

`neeve/products/robin/skills-src/`

And distributable archives in:

`neeve/products/robin/zips/`

Any top-level folder in `skills-src/` is treated as a skill package and must contain `SKILL.md`.

### Source of truth

`skills-src` is canonical. Edit files there, then rebuild zips.

### Sync commands

```bash
# Verify zips and skills-src are in sync
neeve/products/robin/scripts/skills_sync.sh check

# Rebuild zips from skills-src
neeve/products/robin/scripts/skills_sync.sh pack
```

### CI enforcement

Validation CI runs `skills_sync.sh check` on every push and pull request.
If `skills-src` and `zips` drift, CI fails and merge is blocked.
