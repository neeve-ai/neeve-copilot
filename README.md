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

**Stuck, or not sure what to use next?** Ask `neeve` — "help me set up
neeve-copilot" or "what should I use for X" — it's the one agent meant to be
asked first, for setup and for routing across every skill by Design Loop
stage. See [`agents-src/README.md`](neeve/agent/README.md).

**Full usage guide** — per-tool notes, repo setup, and how context is
managed: [`HOW-TO-USE.md`](HOW-TO-USE.md).

> **Keep skills up to date:** run `sync_skills.sh` any time — it pulls the latest
> from this repo and reinstalls everything. Bookmark it or alias it.
> ```bash
> alias sync-skills='bash ~/Projects/src/neeve/neeve-copilot/sync_skills.sh'
> ```

---

## What's Installed

Nine engineering skills that work across every agent, covering the full
Design Loop (see `neeve/README.md`):

| Skill | Trigger phrase | What it does |
|-------|---------------|-------------|
| `to-prd` | "write a PRD for..." | Problem → enterprise-SaaS PRD, led by a CRE-OT security/ops journey |
| `to-erd` | "break this PRD into work items" | PRD → compliance-aware, dependency-ordered work-item breakdown |
| `repo-intel` | "map this repo", "document this project" | Full codebase scan → CONTEXT.md, README gaps, ADR stubs |
| `repo-ask` | "how does X work", "why does X fail", "trace X" | Targeted code trace — always clarifies intent first |
| `to-spec` | "spec this", "write a work item" | Turns a problem into a production-grade Neeve spec, including the Design/architecture lock |
| `implement-spec` | "implement task N", "build this from the spec" | Implements a spec with tests, types, and quality gates |
| `code-review` | "review this PR", "review these changes" | Production code review: correctness, security, contracts |
| `neeve-dls` | "update this component", "fix this DLS issue" | Pixel-perfect DLS changes with localhost visual verification |
| `ot-building-automation` | Niagara/BQL/WebCTRL work | Domain grounding for building-automation repos |

Plus `debug-trace` — not a typical first move, and deliberately not in the
table above. It's invoked *by* the other nine (and by the `neeve` agent) at
the specific step that needs exhaustive call-chain tracing to a
persistence/cache boundary, or real (researched, version-grounded) certainty
about an external library/tool rather than a training-data guess about it.
Ask for it directly with "trace this thoroughly" / "don't just grep this" if
you want that rigor on demand.

### How they chain — the full Design Loop

```
to-prd                          ← PRD: named persona, named outcome
        ↓
neeve-dls (PRD Prototype Mode)  ← optional, UI only
        ↓
to-erd                          ← PRD → dependency-ordered work items
        ↓
repo-ask / repo-intel           ← orient in unfamiliar code, any stage
        ↓
     to-spec                    ← Spec, including Design/architecture lock
        ↓
  implement-spec                ← build it (linter + types + tests must pass)
        ↓
   code-review                  ← quality gate before done
        ↓
   Merge → CI Pass              ← re-enters the loop at the next feature's PRD
```

`debug-trace` sits outside this chain, one level deeper than `repo-ask` —
any step above drops into it when the step specifically requires that
depth, then returns to where it left off.

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

## Beyond Skills: House Rules and the Unified Agent

Skills are one of three ways GitHub Copilot (and Claude Code, Cursor, Codex,
Antigravity) get taught how Neeve works. In short:

- **House rules** are always-on context — culture/ethos, engineering
  principles, quality gates, the "state consequence and gaps" discipline,
  and what Robin's product/repos are — installed once, globally, into each
  tool's own user-level instructions location (`~/.claude/CLAUDE.md`,
  `~/.codex/AGENTS.md`, `~/.copilot/instructions/`). Re-running the
  installer refreshes it. Nothing is ever written into a product repo.
  Sourced from `neeve/foundation.md` and `neeve/engineering-principles.md`.
- **Skills** are the deep how-to, loaded only when a task calls for them —
  all nine of them, bundled behind the agent below, still directly
  invocable on their own.
- **One unified agent, `neeve`**, routes across every skill by Design Loop
  stage and handles setup/onboarding — source at
  [`neeve/agent/`](neeve/agent/README.md),
  rendered into each tool's own native custom-agent mechanism where one
  exists (Claude Code, Copilot, Codex), and into the skill mechanism where
  it doesn't (Cursor, Antigravity). Invocation isn't identical everywhere —
  see that folder's README for exactly how each tool differs. This replaces
  an earlier eight-agent model (`neeve-guide`, `to-prd`, `to-erd`,
  `repo-guide`, plus four specialist reviewers) that duplicated content
  already in the skills and gave Copilot users an eight-item picker instead
  of one router — see `agents-src/README.md`'s "What changed, and why."

Full explanation (written for a non-technical reader too):
[`neeve/products/robin/README.md`](neeve/products/robin/README.md#the-short-version).

---

## The North-Star Pipeline

An idea becomes a PRD, a PRD becomes a prototype, a prototype becomes work
items, and work items flow through the spec pipeline that already exists —
all built and working today:

```
to-prd for a PRD                      ← led by a security/ops-in-CRE-OT
                                         journey; neeve/references/pm-lens.md's
                                         checklist runs as part of it
        ↓
Designer prototypes the UI            ← neeve-dls, PRD Prototype Mode
        ↓ (optional — skipped for non-UI features)
PRD + prototype → to-erd              ← a compliance-aware work-item
                                         breakdown, grounded in the actual
                                         repo(s), not just the PRD's prose
        ↓
Each work item (WI-*) enters the existing, unmodified pipeline:
repo-ask / repo-intel → to-spec → implement-spec → code-review
```

**Built today:** the whole pipeline. `to-prd` and `to-erd` are skills now
(see "Beyond Skills" above), so they auto-trigger in every tool including
Copilot, not just invoked by asking a picker-only agent. The PM and design
lenses (`neeve/references/pm-lens.md`, `design-review.md`) run as part of
`to-prd`/`to-spec` and `neeve-dls`/`code-review` respectively, not as
separate agents to remember.

**Not built yet:**
- **Living context, in full** — `repo-intel` now refreshes the repo-level
        OKF book whenever it catches a stale fact or a real gap, closing the
        per-repo half of this. What's still open: whether
  `context/product-overview.md`'s cross-repo narrative facts stay
  current the same way. A per-repo bot-PR version of a broader mechanism was
  tried and abandoned (see "History" in
  [`docs/Feature-Reference.md`](docs/Feature-Reference.md)) — it fought the
  centralized, nothing-per-repo model this repo settled on; whatever closes
  the remaining gap has to update `context/` itself, in this repo, not
  16 others.

---

## Contributing Skills

Skills live in [`neeve/skills/`](neeve/skills/) (product-specific ones under [`neeve/products/<product>/skills/`](neeve/products/robin/skills/)).
Each skill is a directory with a `SKILL.md` and optional `references/` files.

```bash
# Edit a skill
code neeve/skills/to-spec/SKILL.md

# Test your change locally (reinstalls all skills)
bash sync_skills.sh

# Commit and push — the post-commit hook pushes automatically
git add neeve/skills/
git commit -m "skills: describe your change"
```

See [`neeve/products/robin/README.md`](neeve/products/robin/README.md) for the full
maintainer workflow and CI/release process.
