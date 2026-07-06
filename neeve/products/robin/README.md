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

**These four files are generated, not hand-authored.** They used to be
copy-pasted per repo and drifted (confirmed — two repos' `AGENTS.md` differed
by a missing line nobody noticed). Now all four render from one shared
template so they can't drift silently. See the next section for what that
means and how to use it.

---

## The Whole System, In Plain English

GitHub Copilot (and every other AI coding assistant — Claude Code, Cursor,
Codex) can be taught how to behave in five distinct ways. None of this
requires knowing any code to understand — think of it like onboarding a new
engineer:

| # | Mechanism | Plain-English analogy | What Neeve uses it for | If it's missing or ignored |
|---|---|---|---|---|
| 1 | **Instructions** (`copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md`) | The onboarding doc every new hire reads on day one — always in the back of their mind, every conversation | Neeve's culture (security-first, simplify-don't-accrete), the quality bar, and this repo's own architecture rules | Copilot doesn't know it's touching safety-critical building systems and gives generic, one-size-fits-all advice |
| 2 | **Skills** (`skills-src/`) | A specialist manual the new hire only pulls off the shelf when the task calls for it — e.g. "how do we write a spec here," "how do BQL queries work" | Neeve's spec format, code-review rubric, and (new) building-automation domain knowledge — same file works identically in Claude Code, Copilot, Cursor, Codex | Every engineer (or agent) reinvents Neeve's spec format or review bar from scratch, inconsistently, every time |
| 3 | **Prompts** (`.github/prompts/*.prompt.md`) | A saved speed-dial for something you do often (`/to-spec`) instead of re-explaining the whole task every time | Quick access to the six skills as slash commands | Nothing breaks — it's a convenience shortcut, not a safeguard |
| 4 | **Custom agents** (`.agent.md`) | A specialist you can call into the room who only does one job, with only the tools that job needs | Currently minimal at Neeve — skills already cover the six core workflows. Two org-wide agents exist for "always available, even in a repo with zero local setup" | Nothing breaks day-to-day; this is the least-used layer right now, by design |
| 5 | **Hooks** (`.github/hooks/`) | A helpful colleague standing next to you who says "hey, are you sure?" before something risky — but doesn't grab your keyboard | A warning before a force-push to `main`, or before editing code on a spec-only branch | Nothing is blocked — Neeve deliberately kept hooks warn-only. The actual lock on the door is still CI (a red check that blocks merging), not the hook |

**The one-sentence summary**: instructions set the default mindset, skills
supply the deep how-to when it's relevant, prompts make common skills easy to
invoke, agents are reserved for specialist jobs, and hooks give a friendly
heads-up — but none of them can block a merge on their own. CI is still the
only thing that actually stops bad code from shipping. This system makes
Copilot (and every other agent) consistently Neeve-aware; it doesn't replace
code review or tests.

---

## How This Is Built and Maintained (for whoever edits this repo)

### The pieces

```
neeve/products/robin/
  context-src/
    base.md              ← shared body: culture/ethos, principles, quality gates,
                             layer rules, skill chain — edit this, not a rendered file
    fragments/           ← optional sections, included per-repo based on its yaml
      spec-review-checklist.md
      code-review-checklist.md
      ot-domain-notes.md
    repos/<repo>.yaml    ← per-repo variables: stack, layers, test/lint commands,
                             do-not-modify list, spec_based_development flag,
                             domain_extension, local dev commands
  prompts-src/*.prompt.md ← source for .github/prompts/ slash commands
  hooks-src/              ← source for .github/hooks/ (warn-only guardrails)
  scripts/
    context_render.py/.sh ← the renderer: --check (diff, used by CI) / --write (apply)
    prompts_sync.sh       ← validates prompts-src frontmatter
```

### Process: bring a repo onto this system for the first time

1. Add `context-src/repos/<repo>.yaml` describing that repo (stack, layers,
   test/lint commands, anything not to modify without discussion, and — if
   relevant — how to run it locally). Copy the closest existing example and
   edit it.
2. Render it: `bash scripts/context_render.sh <repo> ../<repo> --write` (run
   from `neeve/products/robin/`, pointing at the target repo's checkout).
   Review the diff in the target repo before committing — the renderer will
   happily overwrite hand-authored content, so read what changed.
3. Install prompts (and hooks, if applicable — see below):
   `bash install.sh --copilot --project /path/to/<repo>`.
4. Add a 4-line caller workflow at `.github/workflows/context-drift.yml` in
   the target repo:
   ```yaml
   name: Context Drift Check
   on: { push: { branches: [main] }, pull_request: {} }
   jobs:
     drift-check:
       uses: neeve-ai/neeve-copilot/.github/workflows/context-drift-check.reusable.yml@main
       with: { repo: <repo> }
   ```
5. If the repo already has a `.vscode/settings.json`, merge in the Copilot
   keys (`chat.instructionsFilesLocations`, `chat.promptFiles`,
   `chat.promptFilesLocations`, `github.copilot.chat.codeGeneration.useInstructionFiles`)
   — don't overwrite other settings, and don't create a `.vscode/` directory
   in a repo that doesn't already have one.
6. Commit everything in the target repo, including the rendered
   `AGENTS.md`/`copilot-instructions.md`/`CLAUDE.md`/`.cursorrules`.

### Process: change something shared across all repos

1. Edit `context-src/base.md` (or the relevant `fragments/*.md`) here in
   `neeve-copilot` — never edit a rendered file in a product repo directly;
   it will be overwritten next render and flagged as drift by CI in the
   meantime.
2. Re-render every repo that should pick up the change and open a PR in each:
   ```bash
   for repo in robin-ai robin-web robin-kb-service ...; do
     bash scripts/context_render.sh "$repo" "../$repo" --write
   done
   ```
3. If a change only applies to one repo, it almost always belongs in that
   repo's `context-src/repos/<repo>.yaml`, not in `base.md`.

### How CI enforcement works (the anti-drift gate)

Each onboarded repo's `.github/workflows/context-drift.yml` calls this repo's
`context-drift-check.reusable.yml`, which checks out `neeve-copilot@main` and
runs `context_render.py <repo> --check` against the calling repo. Any
difference between what's committed and what `context-src` would currently
render fails the check with a diff in the log — never a silent overwrite.
This is the one mechanism that makes the old hand-copy drift structurally
impossible going forward.

### Prompts (`.github/prompts/*.prompt.md`)

Thin slash-command wrappers around the six skills, for surfaces where
automatic skill-matching doesn't trigger (e.g. inline chat). Source lives in
`prompts-src/` — edit there, validate with `scripts/prompts_sync.sh check`,
distribute via `install.sh --copilot --project <path>`.

### Hooks (`.github/hooks/`, warn-only, Preview feature)

Three lifecycle hooks ship in `hooks-src/baseline.hooks.json`: a dangerous-
command guard, a spec/feat branch-purity echo, and a session-start banner.
They are **deliberately warn-only** — they never block an agent action, they
only shorten the feedback loop. The real merge gate stays in each repo's CI
(e.g. `spec-review.yml`). Hooks are only rendered/installed into a repo when
its `context-src/repos/<repo>.yaml` sets `spec_based_development: true`
(currently only `robin-ai`) — don't add them to a repo that doesn't do
spec-based development, they'd just be noise with nothing to warn about.

### Org-wide custom agents (enterprise governance) — separate, additive layer

A small number of always-available, cross-repo Copilot agents that work even
in a repo with no local Copilot setup live in a separate `neeve-ai/.github-private`
repo, not here — see that repo's `README.md` for the staging/promotion
workflow. This is additive to everything above, not a replacement for it.

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

## Maintainer Workflow

Four editable-source trees, each with its own sync/check script, all
validated by the same `ci.yml`:

| Source | Renders/packages to | Sync command |
|---|---|---|
| `skills-src/` | `dist/zips/*.zip` (release archives) | `scripts/skills_sync.sh check\|pack` |
| `context-src/` | a target repo's `AGENTS.md`/`copilot-instructions.md`/`CLAUDE.md`/`.cursorrules` | `scripts/context_render.sh <repo> <path> --check\|--write` |
| `prompts-src/` | a target repo's `.github/prompts/*.prompt.md` | `scripts/prompts_sync.sh check\|list` |
| `hooks-src/` | a target repo's `.github/hooks/` | copied directly by `install.sh --project`, no build step |

### Skills (`skills-src/` → release zips)

Generated archives are written to `neeve/products/robin/dist/zips/`. Any
top-level folder in `skills-src/` is treated as a skill package and must
contain `SKILL.md`. `skills-src` is canonical — edit files there, then
rebuild zips locally when needed.

```bash
# Pull latest + reinstall all skills for every agent (recommended daily driver)
bash sync_skills.sh                          # from repo root

# Verify every skill packages cleanly into a release zip
neeve/products/robin/scripts/skills_sync.sh check

# Build zips from skills-src into neeve/products/robin/dist/zips/
neeve/products/robin/scripts/skills_sync.sh pack
```

### Context, prompts, and hooks (`context-src/`, `prompts-src/`, `hooks-src/`)

See [Always-On Context, Prompts, and Hooks](#the-whole-system-in-plain-english)
above for the full process. Quick reference:

```bash
# Render one repo's context files (from neeve/products/robin/)
bash scripts/context_render.sh <repo> ../<repo> --write   # apply
bash scripts/context_render.sh <repo> ../<repo> --check   # diff only, used by CI

# Validate prompt frontmatter
bash scripts/prompts_sync.sh check
```

### CI enforcement

Validation CI (`neeve-copilot/.github/workflows/ci.yml`) runs, on every push
and pull request:
- `skills_sync.sh check` — fails if a skill can't package into a valid archive
- `prompts_sync.sh check` — fails if a prompt file is missing required frontmatter
- a smoke test that renders every registered repo's context files without error

Per-repo drift (did a product repo's committed `AGENTS.md` etc. fall out of
sync with what `context-src` currently renders) is a separate check that runs
in *each product repo's own CI*, not here — see `context-drift-check.reusable.yml`.

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
