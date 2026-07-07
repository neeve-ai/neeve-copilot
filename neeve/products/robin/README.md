# Neeve Engineering Skills

This is how every AI coding assistant at Neeve — Claude Code, GitHub Copilot,
Cursor, Codex, Antigravity — gets taught the same house rules, the same spec
format, and the same review bar. Set it up once, and it works the same way
no matter which tool you or your teammates use, in every repo, with nothing
ever committed into a product repo.

This covers the `to-spec → implement-spec → code-review` half of Neeve's
pipeline. For the bigger picture — PRD → prototype → ERD work items → spec —
and what's still ahead, see the
[top-level README's north-star pipeline](../../../README.md#the-north-star-pipeline).

---

## The Short Version

AI assistants can be taught to behave a certain way in a few different ways.
Think of it like onboarding a new engineer:

| # | What it's called | What it actually is | Where Neeve uses it |
|---|---|---|---|
| 1 | **House rules** | The onboarding doc every new hire reads on day one — always in the back of their mind | Culture/ethos, engineering principles, quality gates, the "state consequence and gaps" discipline, what Robin is and how its repos fit together. Installed once, globally, on your machine — not a file in any repo |
| 2 | **Skills** | A manual the assistant only opens when the task calls for it | How to write a Neeve spec, how to review code, how to work with our design system, how to work with our building-automation stack |
| 3 | **Cross-tool agents** | A specialist invoked by name, not a manual you have to open | `to-prd` (writes PRDs), `to-erd` (breaks a PRD into work items), `repo-guide` (knows this specific repo) — see `agents-src/` |
| 4 | **Org-wide agents** | A specialist reserved for GitHub-Enterprise-only, company-wide use | A handful of reviewers (security, product, design) — see `neeve/org/`. Reaches github.com Copilot only, once that setup is live |

**One-line summary:** house rules set the mindset everywhere, all the time;
skills give the deep how-to and only load when relevant; cross-tool agents
are specialists you ask for by name, in whichever tool you're using; org-wide
agents are the same idea but GitHub-Enterprise-only, for now. None of them
can stop bad code from shipping — each product repo's own CI still does
that job, unrelated to this repo.

**Why no per-repo instructions files or CI sync here anymore:** an earlier
version of this system rendered `AGENTS.md`/`CLAUDE.md`/etc. into every
product repo and kept them in sync via CI. That meant committing generated
content into 16 separate repos and running GitHub Actions to keep it fresh —
real infrastructure to build and maintain for a problem that VS Code/Copilot
and Claude Code already solve natively: both support **user-level global
instructions** that apply to every workspace on your machine automatically.
So the shared content lives once, here, and installs straight to that
global location — no repo ever needs a file for it.

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

| Tool | Works? | Note |
|-------|--------|------|
| Claude Code (terminal) | ✅ | The main one this is built around |
| VS Code + Claude extension | ✅ | Same skills as the terminal |
| VS Code + GitHub Copilot | ✅ | Only in Copilot's "agent mode" |
| Cursor | ✅ | Skills in the chat panel; house rules need one manual paste (see below) |
| Antigravity | ✅ (skills) / ⚠️ (house rules) | House-rules global-instructions location not yet confirmed for this tool |
| Codex CLI | ✅ | Type `$skill-name` instead of `/skill-name` |

---

## Getting Set Up

```bash
git clone git@github.com:neeve-ai/neeve-copilot.git ~/Projects/src/neeve/neeve-copilot
bash ~/Projects/src/neeve/neeve-copilot/sync_skills.sh
```

That's it. This one command:
1. Installs the 6 skills into every detected tool's global skill directory.
2. Renders the house-rules content from `context-src/base.md` and installs it
   into each tool's global instructions location (merging into
   `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` without touching any other
   personal content already there; writing a standalone file for Copilot).

Bookmark or alias it — re-running it any time picks up the latest from this
repo and refreshes both skills and house rules:
```bash
alias sync-skills='bash ~/Projects/src/neeve/neeve-copilot/sync_skills.sh'
```

**Cursor** stores its global rules in Settings, not a plain file, so this
can't be fully automated. The installer prints a one-time manual step:
open Cursor → Command Palette → "Rules: User Rules" → paste the content it
shows you. Do this once; re-run the installer and re-paste only when
`context-src/base.md` changes materially.

### Choosing specific tools

```bash
bash install.sh                              # auto-detect installed agents
bash install.sh --all                        # every supported agent
bash install.sh --claude-code --cursor       # only specific agents
```

---

## Where Things Get Installed

| Tool | Skills (global) | House rules (global) |
|-------|--------------------------------|-------------------------------|
| Claude Code | `~/.claude/skills/` | `~/.claude/CLAUDE.md` (merged block) |
| GitHub Copilot | `~/.copilot/skills/` | `~/.copilot/instructions/neeve-house-rules.instructions.md` |
| Cursor | `~/.cursor/skills/` | Settings → Rules → User Rules (manual paste) |
| Codex CLI | `~/.codex/skills/` | `~/.codex/AGENTS.md` (merged block) |
| Antigravity | `~/.gemini/antigravity/skills/` | not yet supported |

Nothing is ever written into a product repo. If you see `AGENTS.md`,
`.github/copilot-instructions.md`, `.cursorrules`, `.github/prompts/`, or
`.github/hooks/` show up as uncommitted files in a product repo, that's a
leftover from an earlier design — safe to delete, it isn't part of this
system anymore.

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

## House Rules: Always-On, Every Workspace

Skills only load when needed. House rules are different — the tool reads
them on *every single request, in every repo*, so this is where the culture,
engineering principles, quality gates, and product overview live: what makes
a Neeve engineer's suggestions look like a Neeve engineer wrote them,
regardless of which repo you happen to be in.

**This used to be four separate files, hand-copied into every repo, and
they quietly drifted apart.** Now it's one block of content, installed once
per engineer, refreshed by re-running the installer — there's nothing left
to drift, because there's only one copy.

### The pieces, in one picture

```
neeve-copilot/
  neeve/products/robin/
    context-src/
      base.md              ← the shared write-up: house rules, quality bar,
                               layer rules, skill list, product overview.
                               Edit this — it's the only source of truth
      fragments/           ← sections included in base.md
        production-consequence-and-gaps.md
        (spec-review-checklist.md, ot-domain-notes.md, dls-usage-notes.md,
         code-review-checklist.md — repo-specific, not part of the
         universal house-rules variant; their content lives in the skills
         that already trigger on their own)
      product-overview.md  ← what Robin offers + a repo-contribution table,
                               generated from each repo's own product_role
      repos/<repo>.yaml    ← per-repo facts (stack, test/lint commands, do
                               not modify, local dev) — reference material,
                               not currently distributed anywhere; kept here
                               as the source of truth if a repo-specific
                               delivery mechanism is added later
    scripts/
      context_render.py     ← renders base.md; --house-rules produces the
                               universal-only variant (no repo-specific
                               facts, no repo-conditional fragments)
      merge_house_rules.py  ← idempotently merges that content into
                               ~/.claude/CLAUDE.md / ~/.codex/AGENTS.md
                               without touching the engineer's own content
      test_context_render.py / test_merge_house_rules.py
                              ← stdlib unittest coverage for both, run in CI
  install.sh                ← installs skills + house rules, global only
  sync_skills.sh             ← pulls latest + re-runs install.sh --all
```

### Changing the house rules for everyone

1. Edit `context-src/base.md` (the universal sections — culture/ethos,
   engineering principles, quality gates, production-consequence-and-gaps,
   product overview).
2. Merge that change to `neeve-copilot`'s own `main`.
3. Every engineer picks it up next time they run `sync_skills.sh` — no repo
   to touch, no PR to open anywhere else.

### Verifying what a fresh install would produce

```bash
python3 neeve/products/robin/scripts/context_render.py --house-rules /tmp/preview.md
cat /tmp/preview.md
```

---

## Cross-Tool Agents: to-prd, to-erd, repo-guide

Three specialists, invoked by name rather than a workflow you have to
trigger — `to-prd` (turns a problem into a PRD), `to-erd` (turns a PRD +
optional prototype into a compliance-aware work-item breakdown), and
`repo-guide` (knows this specific repo's role, stack, structure/style,
local dev, and deploy). Source lives in
[`agents-src/`](agents-src/README.md), one `AGENT.md` per agent, rendered
by `scripts/agents_render.py` into every tool's own native custom-agent
mechanism where one exists, and into a Skill where it doesn't.

**Installed by the same `sync_skills.sh`/`install.sh` you already run** —
no separate step. **Invocation differs by tool, on purpose, not by
accident** (researched directly, not assumed — see `agents-src/README.md`
for the full matrix):

| Tool | Where it lands | How you invoke it |
|---|---|---|
| Claude Code | `~/.claude/agents/<name>.md` | auto-triggers on phrasing, or `@agent-<name>` |
| GitHub Copilot (VS Code) | user-profile agents folder, `<name>.agent.md` | pick from the agent picker (not auto-triggered by default) |
| Codex CLI | `~/.codex/agents/<name>.toml` | `/agent` — explicit only, does not auto-trigger |
| Cursor / Antigravity | installed as a Skill instead (no native agent concept in either tool) | auto-triggers on phrasing, same as any other skill |

## Notes Per Tool

### Claude Code (terminal or VS Code extension)
- Skills load from `~/.claude/skills/` in every project
- Check they're there: type `/skills`
- House rules: `~/.claude/CLAUDE.md` (global, every project)

### GitHub Copilot (VS Code, agent mode)
- Personal skills load from `~/.copilot/skills/`
- Check they're there: `/skills` in Copilot Chat (only works in agent mode)
- House rules: `~/.copilot/instructions/neeve-house-rules.instructions.md`
  (`applyTo: "**"`, so it always applies)

### Cursor
- Personal skills load from `~/.cursor/skills/`
- Check they're there: `/skills` in Cursor Chat
- House rules: Settings → Rules → User Rules — one-time manual paste, the
  installer shows you the content to paste

### Codex CLI
- Personal skills load from `~/.codex/skills/`
- Check they're there: `$skills`
- Call one directly: `$code-review`, `$to-spec`, `$implement-spec`
- House rules: `~/.codex/AGENTS.md` (global; Codex also layers in any
  repo-local `AGENTS.md` on top automatically, root-to-leaf, if one exists)

### Antigravity (Google)
- Personal skills load from `~/.gemini/antigravity/skills/`
- Check they're there: `@skills`
- House rules: not yet supported — no confirmed global-instructions file
  location for this tool. Flag it if you find one.

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

**House rules aren't showing up in Copilot:** you need to be in **agent
mode**, not inline chat or quick-fix mode.

**Antigravity says the skills folder is missing:**
```bash
mkdir -p ~/.gemini/antigravity/skills
```
then run the installer again.

**Want the latest version:** just re-run the installer — it's safe to run
any time, it replaces old skill copies and refreshes the house-rules block
in place:
```bash
bash install.sh --all
```

---

## For People Maintaining This Repo

There are two source trees you edit here, each with its own local check:

| You edit | It produces | Command to check it locally |
|---|---|---|
| `skills-src/` | Downloadable `.zip` files for each skill | `scripts/skills_sync.sh check` |
| `context-src/` | The house-rules content installed globally | `scripts/context_render.py --house-rules <path>` (preview) |

`scripts/test_context_render.py` and `scripts/test_merge_house_rules.py`
(stdlib `unittest`, no extra dependency) cover the rendering/merging logic
and run in this repo's own CI, along with `neeve/org/scripts/check_org_sync.py`
(keeps `neeve/org/`'s agent definitions consistent with `security.md`/
`PRINCIPLES.md`).

**Editing a skill:**
```bash
code neeve/products/robin/skills-src/to-spec/SKILL.md   # make your edit
bash sync_skills.sh                                       # reinstall everywhere, to test it
git add neeve/products/robin/skills-src/
git commit -m "skills: describe your change"
```

**Editing the house rules:**
```bash
code neeve/products/robin/context-src/base.md           # make your edit
python3 neeve/products/robin/scripts/context_render.py --house-rules /tmp/preview.md
cat /tmp/preview.md                                       # check it before installing
bash sync_skills.sh                                       # installs it on your own machine
git add neeve/products/robin/context-src/
git commit -m "house-rules: describe your change"
```

**How releases work:** GitHub Actions builds the skill `.zip` files — they
aren't stored in this repo directly.
- Push to `main` → updates the always-current "latest" release
- Push a tag like `robin-skills-v1.2.0` → creates a proper versioned release
