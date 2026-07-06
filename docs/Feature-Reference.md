# Feature Reference: Neeve Copilot Distribution System

## Feature Name
Neeve Copilot Distribution System (Skills, Prompts, Hooks, and Always-On Instructions)

## Description
A central distribution system that gives every Neeve engineer the same AI
skills, slash commands, warn-only hooks, and always-on repo context —
identically, across Claude Code, GitHub Copilot, Cursor, Codex, and
Antigravity — with zero hand-copying. Content lives once in this repo
(`skills-src/`, `prompts-src/`, `hooks-src/`, `context-src/`) and is either
installed to a developer's machine or rendered into a target repo.

## Key Functionalities
- **One-command global install (`sync_skills.sh` → `neeve/products/robin/install.sh --all`)**:
  pulls the latest from this repo and copies the 6 core skills into every
  supported agent's global skill directory (`~/.claude/skills`,
  `~/.codex/skills`, `~/.copilot/skills`, `~/.cursor/skills`,
  `~/.gemini/antigravity/skills`).
- **Project-scoped installs (`install.sh --project <path>`)**: commits
  skills, prompts, and (where applicable) hooks directly into a target
  repo's `.github/` so the whole team gets them on clone, no personal
  install required.
- **Always-on instructions render pipeline (`context_render.py`)**: composes
  `context-src/base.md` + per-repo `context-src/repos/<repo>.yaml` into each
  repo's `AGENTS.md` / `.github/copilot-instructions.md` / `CLAUDE.md` /
  `.cursorrules` — identical content, one source of truth. A reusable CI
  workflow (`context-drift-check.reusable.yml`) fails a repo's CI if its
  committed files don't match a fresh render.
- **Prompts (`.github/prompts/*.prompt.md`)**: slash-command wrappers around
  the 6 skills, for editors that don't auto-trigger skills from natural
  language.
- **Warn-only hooks (`.github/hooks/`)**: session-start banners and
  PreToolUse/PostToolUse checks (dangerous-command guard, spec-branch-purity
  warning, a skill-usage audit log) — never block; CI is still the only
  hard gate.

## User Flow
1. **Day-1 install:** clone this repo, run `bash sync_skills.sh` once — the
   6 skills are now available in every project on the machine, in every
   supported agent.
2. **Verify:** open any project, type `/skills` (Claude Code) or check the
   `/`-command picker (Copilot/Cursor/Codex).
3. **Usage:** the skills trigger automatically on matching phrasing (see the
   trigger-phrase table in the top-level `README.md`), or invoke explicitly
   via `/to-spec`, `/implement-spec`, `/code-review`, `/repo-ask`,
   `/repo-intel`, `/neeve-dls`.
4. **Update:** re-run `bash sync_skills.sh` any time to pick up changes —
   alias it (see top-level README) so it's a one-word habit.
5. **Per-repo setup (maintainers/team leads):** run
   `neeve/products/robin/install.sh --project <repo-path> --copilot` (or the
   relevant agent flag) once per repo to commit skills/prompts/hooks/context
   into that repo's `.github/`, so the whole team gets them without a
   personal install step.

## Technical Implementation
- **Copy, not symlink**: every install path copies files into the target
  location rather than symlinking to a shared source — a project-scoped
  install is meant to be committed and reviewed like any other file, not a
  live pointer back to this repo.
- **No third-party content**: this system only distributes Neeve's own
  `skills-src`/`prompts-src`/`hooks-src`/`context-src` — it does not pull in
  or depend on any external community repo.
- **Render, don't hand-edit**: `AGENTS.md`/`CLAUDE.md`/`copilot-instructions.md`/
  `.cursorrules` are generated files. `context-drift-check` in each product
  repo's CI fails if someone edits a rendered file directly instead of
  `context-src/base.md`.

## Non-functional requirements
- **Compatibility**: install/sync scripts run under bash 3.2 (macOS default)
  without requiring Homebrew bash or other new dependencies.
- **No supply-chain surprises**: no `curl | sh` pattern, no unpinned
  third-party git dependency — installs are a `git clone`/`git pull` of this
  repo plus local file copies only.

## History
This repo previously also shipped a separate, unreconciled distribution path
(`install.sh`/`load_agents.sh` at the repo root, curl-piped, pulling in a
third-party `github/awesome-copilot` repo and three placeholder skills via
`~/.agents/skills/`) that delivered none of Neeve's real skills, prompts, or
hooks. It was removed — this document now describes the one real path.
