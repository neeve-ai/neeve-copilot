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

That's it. The skills are now available in every project on your machine.

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

- Per-agent install paths and verification commands
- Always-on context files (CLAUDE.md, AGENTS.md, .cursorrules) — **now generated**,
  not hand-authored, from `context-src/`; see that README's "Whole System, In Plain
  English" section for what changed and why
- Project-scoped skill installation (commit skills to a repo for team sharing)
- Prompts (`.github/prompts/`) and warn-only hooks (`.github/hooks/`)
- Troubleshooting

---

## Beyond Skills: Instructions, Prompts, and Hooks

Skills are one of five ways GitHub Copilot (and Claude Code, Cursor, Codex)
can be taught how Neeve works. In short:

- **Instructions** (`AGENTS.md` / `copilot-instructions.md` / `CLAUDE.md` /
  `.cursorrules`) are always-on context, generated per repo from a shared
  template so they can't drift out of sync by hand.
- **Prompts** (`.github/prompts/`) are slash-command shortcuts to the six
  skills above.
- **Hooks** (`.github/hooks/`) give a warning before a risky action (force-push
  to `main`, editing code on a spec-only branch) — deliberately warn-only;
  CI is still the only thing that actually blocks a bad merge.
- **Custom agents** are reserved for specialist, org-wide use cases and live
  in a separate `neeve-ai/.github-private` repo.

Full explanation (written for a non-technical reader too) and the process for
onboarding a repo or changing the shared template:
[`neeve/products/robin/README.md`](neeve/products/robin/README.md#the-whole-system-in-plain-english).

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
