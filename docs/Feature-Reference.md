# Feature Reference: Neeve Copilot Distribution System

## Feature Name
Neeve Copilot Distribution System (Skills and Global House Rules)

## Description
A central distribution system that gives every Neeve engineer the same AI
skills and house rules — identically, across Claude Code, GitHub Copilot,
Cursor, Codex, and Antigravity — with zero hand-copying. Global content
lives once in this repo (`neeve/skills/`, `neeve/context/`,
`neeve/agent/`) and installs to each engineer's machine. The one
deliberate per-repo artifact is the OKF book
(introduction.md/index.md/appendix.md + its pre-commit freshness hook),
set up per product repo by `neeve/init-repo.sh` — see `neeve/README.md`.

## Key Functionalities
- **One-command global install (`sync_skills.sh` → `neeve/install.sh --all`)**:
  pulls the latest from this repo and installs both:
  - all 10 skills (org-level + product-level skills roots) into every supported agent's global skill directory
    (`~/.claude/skills`, `~/.codex/skills`, `~/.copilot/skills`,
    `~/.cursor/skills`, `~/.gemini/antigravity/skills`)
  - the house-rules content (culture/ethos, engineering principles, quality
    gates, production-consequence discipline, product overview) into each
    tool's own user-level instructions location — merged into
    `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` without disturbing any
    personal content already there, written standalone for Copilot
    (`~/.copilot/instructions/neeve-house-rules.instructions.md`)
- **House-rules render (`context_render.py --house-rules`)**: produces the
  universal-only variant of `context/base.md` — no repo-specific
  stack/commands/do-not-modify facts, no repo-conditional fragments (those
  live in the skills that already trigger on their own: `to-spec`,
  `ot-building-automation`, `neeve-dls`).
- **Idempotent merge (`merge_house_rules.py`)**: re-running the installer
  updates the house-rules block in `~/.claude/CLAUDE.md`/`~/.codex/AGENTS.md`
  in place, marked by BEGIN/END comments, without touching anything else an
  engineer has in that file.

## User Flow
1. **Day-1 install:** clone this repo, run `bash sync_skills.sh` once — the
   all skills and the house rules are now available in every project on the
   machine, in every supported agent.
2. **Verify:** open any project, type `/skills` (Claude Code) or check the
   `/`-command picker (Copilot/Cursor/Codex). Preview the house rules with
   `python3 neeve/scripts/context_render.py --house-rules /tmp/preview.md`.
3. **Usage:** the skills trigger automatically on matching phrasing, or
   invoke explicitly via `/to-spec`, `/implement-spec`, `/code-review`,
   `/repo-ask`, `/repo-intel`, `/neeve-dls`. House rules apply automatically,
   every request, every repo — no invocation needed.
4. **Update:** re-run `bash sync_skills.sh` any time to pick up changes —
   alias it (see top-level README) so it's a one-word habit.
5. **Cursor's global rules** live in Settings, not a plain file, so the
   installer can't write them automatically — it prints a one-time manual
   paste step (Command Palette → "Rules: User Rules").

## Technical Implementation
- **Copy, not symlink**: skill installs copy files into the target location
  rather than symlinking to a shared source.
- **Merge, not overwrite**: house-rules installs into `~/.claude/CLAUDE.md`/
  `~/.codex/AGENTS.md` only replace a clearly marked block, preserving any
  other personal content in that file.
- **No third-party content**: this system only distributes Neeve's own
  `skills`/`context` — it does not pull in or depend on any external
  community repo.
- **Nothing committed into product repos**: no `.github/copilot-instructions.md`,
  `AGENTS.md`, `.cursorrules`, prompts, or hooks are ever written into any of
  Neeve's product repos. If you find any of those as uncommitted files in a
  product repo, they're leftovers from an earlier design — safe to delete.

## Non-functional requirements
- **Compatibility**: install/sync scripts run under bash 3.2 (macOS default)
  without requiring Homebrew bash or other new dependencies.
- **No supply-chain surprises**: no `curl | sh` pattern, no unpinned
  third-party git dependency — installs are a `git clone`/`git pull` of this
  repo plus local file copies only.

## History
Two earlier designs were tried and abandoned in the same session that built
this one:
1. A March-2026 curl-piped installer (`install.sh`/`load_agents.sh` at the
   repo root) that pulled in a third-party `github/awesome-copilot` repo and
   three placeholder skills via `~/.agents/skills/` — delivered none of
   Neeve's real skills. Removed.
2. A per-repo render-and-commit model: `AGENTS.md`/`CLAUDE.md`/
   `.github/copilot-instructions.md`/`.cursorrules` generated and committed
   into all 16 product repos, kept fresh via a CI workflow that opened a
   review PR on every merge. This worked, but meant maintaining GitHub
   Actions automation across 16 repos for something VS Code/Copilot and
   Claude Code already solve natively via user-level global instructions.
   Replaced by the current design — nothing is committed into any product
   repo at all.
