# Neeve Engineering Skills

This is how every AI coding assistant at Neeve — Claude Code, GitHub Copilot,
Cursor, Codex, Antigravity — gets taught the same house rules, the same spec
format, and the same review bar. Set it up once, and it works the same way
no matter which tool you or your teammates use.

---

## The Short Version

AI assistants can be taught to behave a certain way in five different ways.
Think of it like onboarding a new engineer:

| # | What it's called | What it actually is | Where Neeve uses it |
|---|---|---|---|
| 1 | **Instructions** | The onboarding doc every new hire reads on day one — always in the back of their mind | House rules: keep it simple, assume zero trust, name the real-world stakes. Files: `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `.cursorrules` |
| 2 | **Skills** | A manual the assistant only opens when the task calls for it | How to write a Neeve spec, how to review code, how to work with our design system, how to work with our building-automation stack |
| 3 | **Prompts** | A saved shortcut for something you do often, like a speed-dial | Typing `/to-spec` instead of explaining the whole spec process every time |
| 4 | **Custom agents** | A specialist you bring in for one job only | A handful of company-wide reviewers (security, product, design) — see the note near the bottom |
| 5 | **Hooks** | A colleague who says "hey, are you sure?" before something risky — but doesn't stop you | A warning before a risky git command. It only warns, it never blocks — the thing that actually blocks bad code is still a green/red check in CI |

**One-line summary:** instructions set the mindset, skills give the deep
how-to, prompts make that quick to reach, agents are for specialist jobs, and
hooks give a heads-up. None of them can stop bad code from shipping —
automated checks (CI) still do that job.

---

## The Six Skills

| Skill | What it does |
|-------|-------------|
| `repo-intel` | Scans a whole codebase and writes it up — a CONTEXT.md doc, gaps in the README, missing decision records |
| `repo-ask` | Answers "how does X work" by tracing the actual code, not guessing |
| `to-spec` | Turns a feature idea or bug into a proper Neeve-style spec, ready to hand off |
| `implement-spec` | Builds a spec's task: reuse what exists, write typed code, write real tests |
| `code-review` | A thorough pre-merge review: does it match the spec, is it correct, is it secure |
| `neeve-dls` | Makes UI changes match our design system exactly, down to the pixel |

They're meant to be used in order:

```
repo-ask / repo-intel   ← get to know the code first
        ↓
     to-spec            ← agree what you're building, in writing
        ↓
  implement-spec         ← build it — all 7 quality checks must pass
        ↓
   code-review           ← final check before it ships
```

If the work touches UI, `neeve-dls` runs alongside `implement-spec`, and
`code-review` still happens after.

**The 7 checks every change must pass:** no linter warnings, no type errors,
tests cover at least 95% of the code, the main flow has an integration test,
no obvious N+1/scale problem, a security pass (inputs, auth, secrets,
dependencies), and a clean code review.

---

## Works Everywhere

One set of files, every tool:

| Tool | Works? | Note |
|-------|--------|------|
| Claude Code (terminal) | ✅ | The main one this is built around |
| VS Code + Claude extension | ✅ | Same skills as the terminal |
| VS Code + GitHub Copilot | ✅ | Only in Copilot's "agent mode" |
| Cursor | ✅ | In the chat panel |
| Antigravity | ✅ | |
| Codex CLI | ✅ | Type `$skill-name` instead of `/skill-name` |

---

## Getting Set Up

### The fast way

From wherever you keep the `neeve-copilot` checkout:

```bash
bash sync_skills.sh
```

This grabs the latest version and installs every skill for every tool on
your machine. Safe to run again any time you want to pick up changes.

### Doing it by hand

If you can't or don't want to pull the whole repo (offline, or you just want
a specific state):

```
neeve-skills/
  install.sh       ← the installer
  AGENTS.md        ← copy this into each repo you work in
  README.md        ← this file
  skills-src/      ← the source files, if you have a full checkout
```

No checkout handy? Download the latest release from GitHub — it has the
installer, `AGENTS.md`, this README, and everything already packaged.

**Step 1 — install:**

```bash
bash install.sh                              # auto-detects what's on your machine
bash install.sh --claude-code --codex --cursor   # only specific tools
bash install.sh --all                        # every supported tool
bash install.sh --all --project /path/to/robin-ai   # also set up one repo for the whole team
```

**Step 2 — add always-on context to a repo:**

```bash
cp AGENTS.md /path/to/robin-ai/AGENTS.md
git add AGENTS.md
git commit -m "chore: add agent instructions"
```

Copilot, Codex, and Antigravity all read `AGENTS.md` automatically. Claude
Code reads `CLAUDE.md` instead — more on this below.

**Step 3 — share it with your team (optional but worth doing):**

If you used `--project`, commit what got installed so everyone gets it for
free on `git clone`:

```bash
cd /path/to/robin-ai
git add .claude/skills/ .github/skills/ .agents/skills/ .cursor/skills/
git commit -m "chore: add Neeve engineering skills"
```

---

## Where Things Get Installed

| Tool | On your machine only | Shared with the team (committed to the repo) |
|-------|--------------------------------|-------------------------------|
| Claude Code | `~/.claude/skills/` | `.claude/skills/` |
| GitHub Copilot | `~/.copilot/skills/` | `.github/skills/` |
| Cursor | `~/.cursor/skills/` | `.cursor/skills/` |
| Codex CLI | `~/.codex/skills/` | `.agents/skills/` |
| Antigravity | `~/.gemini/antigravity/skills/` | `.agents/skills/` |

Best of both: install on your own machine so it's always there, *and* commit
the repo-scoped copy so a new teammate gets it the moment they clone.

---

## Turning Skills On

Skills load themselves automatically when what you ask for matches one:

| What you say | Skill that answers |
|-------------|-------------|
| "map this repo", "document this project" | `repo-intel` |
| "how does X work", "why does X fail", "where is X defined" | `repo-ask` |
| "spec this feature", "turn this bug into a work item" | `to-spec` |
| "implement task 3", "build this from the spec" | `implement-spec` |
| "review this PR", "audit these changes" | `code-review` |
| "update this DLS component", "fix this UI to match the design" | `neeve-dls` |

Or call one directly:

```
Claude Code / Copilot / Cursor / Antigravity:
  /repo-intel  /repo-ask  /to-spec  /implement-spec  /code-review  /neeve-dls

Codex CLI:
  $repo-intel  $repo-ask  $to-spec  $implement-spec  $code-review  $neeve-dls
```

---

## Always-On Context Files

Skills only load when needed. These four files are different — the tool
reads them on *every single request*, so this is where the house rules and
this repo's own facts (stack, test commands, what not to touch) live:

| Tool | File it reads |
|-------|---------------|
| Claude Code | `CLAUDE.md` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Cursor | `.cursorrules` |
| Codex, Antigravity, and Copilot | `AGENTS.md` (all three read this one too) |

**Important: don't write these by hand.** They used to be copied by hand into
each repo, and they quietly drifted apart — two repos' `AGENTS.md` files
differed by one missing line that nobody caught. Now all four files are
generated from one shared template, so that can't happen silently again.
The next section explains how.

---

## How the Shared Template Works

### The pieces, in one picture

```
neeve/products/robin/
  context-src/
    base.md              ← the shared write-up: house rules, quality bar,
                             layer rules, skill list. Edit this, not the
                             generated files
    fragments/           ← optional add-on sections, only included for
                             repos that need them
      spec-review-checklist.md
      code-review-checklist.md
      ot-domain-notes.md
      dls-usage-notes.md
    repos/<repo>.yaml    ← the facts specific to one repo: its stack, its
                             layers, its test/lint commands, what not to
                             touch, how to run it locally
  prompts-src/*.prompt.md ← source for the `/to-spec`-style shortcuts
  hooks-src/              ← source for the warning-only guardrails
  scripts/
    context_render.py/.sh ← turns base.md + one repo's yaml into that
                             repo's four files
    prompts_sync.sh       ← checks the shortcut files are well-formed
```

### Adding a new repo to this system

1. Write `context-src/repos/<repo>.yaml` for that repo — copy the closest
   existing example and edit it: its stack, its layout, its test/lint
   commands, anything that shouldn't be touched without asking, and (if it
   applies) how to run it locally.
2. Generate its files:
   ```bash
   bash scripts/context_render.sh <repo> ../<repo> --write
   ```
   Read the diff before committing — this will happily overwrite anything
   already there, so check what changed.
3. Add the shortcuts (and warning hooks, if this repo uses them — see
   below):
   ```bash
   bash install.sh --copilot --project /path/to/<repo>
   ```
4. Add a small file so this repo automatically gets flagged if it ever falls
   out of sync — `.github/workflows/context-drift.yml` in the target repo:
   ```yaml
   name: Context Drift Check
   on: { push: { branches: [main] }, pull_request: {} }
   jobs:
     drift-check:
       uses: neeve-ai/neeve-copilot/.github/workflows/context-drift-check.reusable.yml@main
       with: { repo: <repo> }
   ```
5. If that repo already has a `.vscode/settings.json`, add these lines to it
   (don't replace the file, just add to it, and don't create the file if it
   doesn't already exist):
   ```json
   "chat.instructionsFilesLocations": { ".github/instructions": true },
   "chat.promptFiles": true,
   "chat.promptFilesLocations": { ".github/prompts": true },
   "github.copilot.chat.codeGeneration.useInstructionFiles": true
   ```
6. Commit everything, including the four generated files.

### Changing something for every repo at once

1. Edit `context-src/base.md` (or the relevant file under `fragments/`) —
   never edit a generated file directly, it'll just get overwritten next
   time someone regenerates it.
2. Regenerate every repo that should pick up the change, and open a PR in
   each:
   ```bash
   for repo in robin-ai robin-web robin-kb-service ...; do
     bash scripts/context_render.sh "$repo" "../$repo" --write
   done
   ```
3. If a change is really only relevant to one repo, it belongs in that
   repo's own `context-src/repos/<repo>.yaml`, not in the shared `base.md`.

### How we catch drift automatically

Every onboarded repo has a small check in its own CI that regenerates its
four files fresh and compares them to what's actually committed. If they
don't match, the check turns red with the exact difference shown — nobody
has to remember to check by hand, and nothing gets silently overwritten
without a human seeing the diff first.

### The shortcut files (prompts)

`.github/prompts/*.prompt.md` — one-line wrappers so you can type `/to-spec`
even somewhere the skill wouldn't otherwise auto-trigger (like inline chat).
Source is in `prompts-src/`; check them with `scripts/prompts_sync.sh check`;
they install the same way skills do, via `install.sh --copilot --project`.

### The warning hooks

`.github/hooks/` — three small warnings, and nothing more:
- flags an obviously dangerous command (like force-pushing to `main`)
- flags editing code on a spec-only branch (specs and code are meant to be
  reviewed separately)
- prints a short reminder at the start of a session about this repo's spec
  process

**They only warn. They never block anything.** The actual gate that stops
bad code from merging is still each repo's CI. Hooks are only turned on for
repos doing spec-based development (right now, just `robin-ai`) — there's no
point warning about a spec-only branch in a repo that doesn't have one.

### Company-wide specialist reviewers

A handful of always-available reviewers (a security specialist, a product
specialist, a design specialist, plus the general one) are maintained at
[`neeve/org/`](../org/README.md) in this repo, and exported to a separate,
private repo — `neeve-ai/.github-private` — so they're available even in a
repo that hasn't set any of this up yet. See `neeve/org/README.md` for the
export steps. This is additional to everything above, not a replacement
for it.

---

## Notes Per Tool

### Claude Code (terminal or VS Code extension)
- Skills load from `~/.claude/skills/` in every project
- Check they're there: type `/skills`
- Repo-specific context: `CLAUDE.md` at the repo root

### GitHub Copilot (VS Code, agent mode)
- Personal skills load from `~/.copilot/skills/`
- Repo skills load from `.github/skills/` — commit these
- Repo-specific context: `.github/copilot-instructions.md`
- Check they're there: `/skills` in Copilot Chat (only works in agent mode)
- Copilot also reads `AGENTS.md` at the repo root, automatically

### Cursor
- Personal skills load from `~/.cursor/skills/`
- Repo skills load from `.cursor/skills/`
- Repo-specific context: `.cursorrules`
- Check they're there: `/skills` in Cursor Chat

### Codex CLI
- Personal skills load from `~/.codex/skills/` or `~/.agents/skills/`
- Repo skills load from `.agents/skills/`
- Reads `AGENTS.md` at the repo root automatically
- Check they're there: `$skills`
- Call one directly: `$code-review`, `$to-spec`, `$implement-spec`

### Antigravity (Google)
- Personal skills load from `~/.gemini/antigravity/skills/`
- Repo skills load from `.agents/skills/` (same folder Codex uses)
- Reads `AGENTS.md` at the repo root automatically
- Check they're there: `@skills`

---

## If Something's Not Working

**A skill doesn't show up after installing:** restart the tool or start a
new session — skills only load when a session starts.

**Nesting looks wrong after a manual unzip:** the correct layout is
`~/.claude/skills/code-review/SKILL.md`, not a doubled-up
`.../code-review/code-review/SKILL.md`. The installer avoids this
automatically — if you unzipped by hand, check with:
```bash
ls ~/.claude/skills/code-review/
# should show: SKILL.md  agents/  references/
```

**Copilot isn't picking up `.github/skills/`:** you need to be in **agent
mode**, not inline chat or quick-fix mode. That's the only mode where Copilot
looks for skills.

**Antigravity says the folder is missing:**
```bash
mkdir -p ~/.gemini/antigravity/skills
```
then run the installer again.

**Want the latest version:** just re-run the installer — it's safe to run
any time, it replaces old copies:
```bash
bash install.sh --all
```

---

## For People Maintaining This Repo

There are four things you can edit here, and each has its own
check-it-still-works command. All four are checked automatically whenever
someone pushes a change:

| You edit | It produces | Command to check/apply it |
|---|---|---|
| `skills-src/` | Downloadable `.zip` files for each skill | `scripts/skills_sync.sh check` (verify) / `pack` (build) |
| `context-src/` | A repo's `AGENTS.md` / `copilot-instructions.md` / `CLAUDE.md` / `.cursorrules` | `scripts/context_render.sh <repo> <path> --check` (verify) / `--write` (apply) |
| `prompts-src/` | A repo's `.github/prompts/*.prompt.md` | `scripts/prompts_sync.sh check` |
| `hooks-src/` | A repo's `.github/hooks/` | No build step — copied as-is by `install.sh --project` |

**Editing a skill:**
```bash
code neeve/products/robin/skills-src/to-spec/SKILL.md   # make your edit
bash sync_skills.sh                                       # reinstall everywhere, to test it
git add neeve/products/robin/skills-src/
git commit -m "skills: describe your change"              # a commit hook pushes it automatically
```

**What the automatic checks catch:**
- a skill that can't be packaged into a working `.zip`
- a shortcut (`.prompt.md`) file that's missing required setup at the top
- any repo's generated files that would come out different from what's
  currently committed there (this runs inside *that repo's* own checks, not
  here)

**How releases work:** GitHub Actions builds the `.zip` files — they aren't
stored in this repo directly.

- Push to `main` → updates the always-current "latest" release
- Push a tag like `robin-skills-v1.2.0` → creates a proper versioned release

Either way it rebuilds and tests: `repo-intel.zip`, `repo-ask.zip`,
`code-review.zip`, `to-spec.zip`, `implement-spec.zip`, `neeve-dls.zip`, and
a bundle containing the installer, `AGENTS.md`, this README, and every skill.
