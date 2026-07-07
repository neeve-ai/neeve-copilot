# Neeve Copilot

AI skills and agents for the Neeve engineering team. One install, every agent
(Claude Code, Copilot, Cursor, Codex, Antigravity).

## Day 1 Setup

```bash
# 1. Clone this repo
git clone git@github.com:neeve-ai/neeve-copilot.git ~/Projects/src/neeve/neeve-copilot

# 2. Install all engineering skills across every agent on your machine
bash ~/Projects/src/neeve/neeve-copilot/sync_skills.sh

# 3. Verify in Claude Code
#    Open any project, type: /skills
```

That's it. The skills, and Neeve's shared house rules (culture/ethos,
engineering principles, quality gates, product overview), are now available
in every project on your machine — nothing is committed into any product
repo to make this work.

> **Keep skills up to date:** run `sync_skills.sh` any time — it pulls the latest
> from this repo and reinstalls everything. Bookmark it or alias it.
> ```bash
> alias sync-skills='bash ~/Projects/src/neeve/neeve-copilot/sync_skills.sh'
> ```

---

## What's Installed

Six engineering skills that work across every agent:

| Skill | Trigger phrase | What it does |
|-------|---------------|-------------|
| `repo-intel` | "map this repo", "document this project" | Full codebase scan → CONTEXT.md, README gaps, ADR stubs |
| `repo-ask` | "how does X work", "why does X fail", "trace X" | Targeted code trace — always clarifies intent first |
| `to-spec` | "spec this", "write a work item" | Turns a problem into a production-grade Neeve spec |
| `implement-spec` | "implement task N", "build this from the spec" | Implements a spec with tests, types, and quality gates |
| `code-review` | "review this PR", "review these changes" | Production code review: correctness, security, contracts |
| `neeve-dls` | "update this component", "fix this DLS issue" | Pixel-perfect DLS changes with localhost visual verification |

### How they chain

```
repo-ask / repo-intel          ← start here on unfamiliar code
        ↓
     to-spec                   ← turn the problem into a spec
        ↓
  implement-spec                ← build it (linter + types + tests must pass)
        ↓
   code-review                  ← quality gate before done
```

Every implementation task must pass **7 quality gates**: linter (zero warnings),
strict type checking (zero errors), unit tests (≥95% coverage), integration tests,
scale check, security check, and code review. The skills enforce this automatically.

---

## Detailed Setup and Agent Notes

See [`neeve/products/robin/README.md`](neeve/products/robin/README.md) for:

- Per-tool install paths and verification commands
- House rules (culture/ethos, engineering principles, quality gates, product
  overview) — installed globally via the same installer, merged into each
  tool's own user-level instructions file, never committed into any repo
- Troubleshooting

---

## Beyond Skills: House Rules and Custom Agents

Skills are one of three ways GitHub Copilot (and Claude Code, Cursor, Codex)
get taught how Neeve works. In short:

- **House rules** are always-on context — culture/ethos, engineering
  principles, quality gates, the "state consequence and gaps" discipline,
  and what Robin's product/repos are — installed once, globally, into each
  tool's own user-level instructions location (`~/.claude/CLAUDE.md`,
  `~/.codex/AGENTS.md`, `~/.copilot/instructions/`). Re-running the
  installer refreshes it. Nothing is ever written into a product repo.
- **Skills** are the deep how-to, loaded only when a task calls for them.
- **Custom agents** are reserved for specialist, org-wide use cases. Their
  source lives in this repo at
  [`neeve/org/`](neeve/org/README.md) and is exported to a separate
  `neeve-ai/.github-private` repo when the org enables enterprise custom
  agents — see that folder's README for the export steps.

Full explanation (written for a non-technical reader too):
[`neeve/products/robin/README.md`](neeve/products/robin/README.md#the-short-version).

---

## Roadmap: The North-Star Pipeline

Everything above is shipped and working today. It's building toward one
pipeline: an idea becomes a PRD, a PRD becomes a prototype, a prototype
becomes work items, and work items flow through the spec pipeline that
already exists.

```
PM writes a PRD                       ← neeve-pm-partner reviews it ad hoc
        ↓
Designer prototypes the UI            ← neeve-dls, prototype mode
        ↓
PRD + prototype → an ERD              ← Engineering (Requirements) Document:
                                         a work-item breakdown, modeled on
                                         robin-adr's existing
                                         Enterprise_Readiness_Workitems.md
        ↓
Each work item (WI-*) enters the existing, unmodified pipeline:
repo-ask / repo-intel → to-spec → implement-spec → code-review
```

**Built today:** the bottom half of that pipeline (`to-spec` through
`code-review`), plus `neeve-pm-partner` and `neeve-design-partner` in
[`neeve/org/`](neeve/org/README.md) as ad hoc reviewers.

**Not built yet:**
- **`to-prd`** — a skill that turns a problem into a PRD, upstream of
  `to-spec`. `neeve-pm-partner`'s review checklist is the intended Phase-1
  gate for it, not a replacement.
- **`to-erd`** — a skill that turns a PRD + prototype into a new
  `robin-adr/erd/<feature-slug>-workitems.md`, whose individual `WI-*` items
  are consumable by the existing `to-spec` unmodified.
- **Living context** — `context-src/product-overview.md` and
  `context-src/repos/*.yaml` (the source for the house rules'
  product-overview section) should stay current as the product evolves,
  without anyone having to remember to update them by hand, framed as a
  feature/bug worth documenting, never a trade secret. A per-repo bot-PR
  version of this was tried and abandoned (see "History" in
  [`docs/Feature-Reference.md`](docs/Feature-Reference.md)) — it fought the
  centralized, nothing-per-repo model this repo settled on. Whatever
  replaces it has to update `context-src/` itself, in this repo, not 16
  others; the exact mechanism is still an open design question, not yet
  built.

---

## Contributing Skills

Skills live in [`neeve/products/robin/skills-src/`](neeve/products/robin/skills-src/).
Each skill is a directory with a `SKILL.md` and optional `references/` files.

```bash
# Edit a skill
code neeve/products/robin/skills-src/to-spec/SKILL.md

# Test your change locally (reinstalls all skills)
bash sync_skills.sh

# Commit and push — the post-commit hook pushes automatically
git add neeve/products/robin/skills-src/
git commit -m "skills: describe your change"
```

See [`neeve/products/robin/README.md`](neeve/products/robin/README.md) for the full
maintainer workflow and CI/release process.
