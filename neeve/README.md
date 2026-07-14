# The Neeve Agentic Coding Framework

One page: what lives here, and the three-pillar architecture it implements —
**4 Layers of Context**, **Harness with Hooks**, **Design Loops**. Everything
below is markdown/yaml (Open Knowledge Format — no tool-proprietary syntax),
projected into each AI tool (Claude Code, GitHub Copilot, Codex, Cursor,
Antigravity) by the render/install layer, so the knowledge is written once
and every harness reads the same thing.

## Pillar 1 — 4 Layers of Context

Base of the pyramid = broadest and most stable; apex = narrowest and most
volatile. Each layer loads only what its scope needs — that's the answer to
context bloat, not one giant file.

| Layer | What | Canonical source | Reaches the engineer via |
|---|---|---|---|
| 04. Neeve Foundation | What Neeve is, why, culture, products, customers, personas | [`foundation.md`](foundation.md) + per-product [`products/robin/context/product-overview.md`](products/robin/context/product-overview.md) | House rules, installed globally (`install.sh`) |
| 03. Engineering Principles | SDLC process principles per Design Loop stage; security/quality canonicals | [`engineering-principles.md`](engineering-principles.md) + [`references/`](references/) (quality-gates, security via code-review, pm-lens, design-review) | House rules + cited by every skill |
| 02. Repository-Level Context | The per-repo **OKF book**, under `.help/` (a dot-directory so `.dockerignore` can exclude it): `introduction.md` (agent-facing README: stack, wiring, make/docker/deploy) · `index.md` (functional area → location) · `appendix.md` (public symbols: purpose, dependencies, impact) | **Committed into each product repo** — scaffolded by [`init-repo.sh`](init-repo.sh), filled by the `repo-intel` skill, kept fresh by the committed `.githooks/pre-commit` | Read directly in the repo by any harness |
| 01. Custom & User Context | Developer-local instructions and overrides | Not in any repo — content outside the `BEGIN/END NEEVE` markers in `~/.claude/CLAUDE.md`, `CLAUDE.local.md`, local settings | Owned by the developer; the installer never touches it |

## Pillar 2 — Harness with Hooks

Instructions alone are not enforcement — deterministic checks are. What runs
where:

| Check | Mechanism | Lives at |
|---|---|---|
| Repo-book freshness | `pre-commit-context-sync` — manifest-hash, index structural diff, public-symbol diff; no model call, warn-only until a repo opts into blocking | [`templates/hooks/pre-commit-context-sync`](templates/hooks/pre-commit-context-sync), installed per repo by `init-repo.sh` |
| `--no-verify` backstop | Same script, `--all`, as a required PR status | [`templates/ci/context-sync-check.yml`](templates/ci/context-sync-check.yml) |
| Integration verification | Per-repo PR-build job running the repo's real integration tests (EDIT-ME template — fails until pointed at the real command) | [`templates/ci/integration-verify.yml`](templates/ci/integration-verify.yml) |
| Context freshness on the engineer's machine | Claude Code `SessionStart` hook pulls this repo + reinstalls, quietly, only when something changed | [`hooks/refresh-context.sh`](hooks/refresh-context.sh) |
| Framework self-consistency | CI: agent routes every skill, shared refs match canonical, skills/prompts pack cleanly, renderer tests | [`scripts/check_org_sync.py`](scripts/check_org_sync.py) + `.github/workflows/ci.yml` |
| Quality gates (7) | Linter · strict types · unit ≥95% · integration · scale · security · code review — specced by `to-spec`, enforced by `implement-spec`, verified by `code-review` | [`references/quality-gates.md`](references/quality-gates.md) (canonical; skills carry generated copies) |

## Pillar 3 — The Design Loop

Eight stages, each with an acceptance contract that must hold before the
next stage starts. CI Pass re-enters at the next feature's PRD — a loop, not
a line. The unified `neeve` agent's routing table
([`agent/neeve/AGENT.md`](agent/neeve/AGENT.md)) is this table made
operational.

| # | Stage | Owner | Acceptance contract |
|---|---|---|---|
| 1 | PRD | `to-prd` skill | Named persona + named operational outcome |
| 2 | Design | `to-spec` Phase 3.5 | Component & data-flow diagram locked |
| 3 | ERD | `to-erd` skill | Work items dependency-ordered, repo-grounded |
| 4 | Spec | `to-spec` skill | SOLID mapped per FR; 8-check rubric passed |
| 5 | Implement | `implement-spec` (+ `neeve-dls`, `ot-building-automation`) | All 7 quality gates pass |
| 6 | Code Review | `code-review` skill | Checklist verified; security pass when the surface warrants |
| 7 | Merge | process (agent supervises) | Conflicts resolved, hook checks pass; human approves |
| 8 | CI Pass | process (agent points at real CI) | Pipeline green — then loop to 1 |

`repo-ask`/`repo-intel` orient before any stage; `debug-trace` is the
one-level-deeper grounding any stage drops into.

## What's in this directory

```
neeve/
├── foundation.md  engineering-principles.md  references/    # Layers 04–03
├── context/          # base.md (house rules) + tier-1 fragments
├── skills/           # 8 product-agnostic SDLC skills
├── agent/neeve/      # THE unified agent (see agent/README.md)
├── prompts/          # slash-command wrappers
├── hooks/            # SessionStart freshness hook
├── templates/            # per-repo hook + CI templates (Layer 02 tooling)
├── install.sh            # global install (skills, house rules, agent, hook)
├── init-repo.sh          # per-repo init (OKF book scaffold + pre-commit hook)
├── scripts/              # render/sync/merge + tests
└── products/robin/       # product-specific: product overview,
                          #   OT/DLS fragments, neeve-dls + ot-building-automation skills
```

A second product would add `products/<name>/` with its own `context/` and
`skills/` — nothing at this level changes.

## The two commands that matter

```bash
# Once per machine (and any time, to refresh):
bash sync_skills.sh

# Once per cloned product repo:
bash <neeve-copilot>/neeve/init-repo.sh        # then run the repo-intel skill
```

## Adding or changing content in this repo

See [`CONTRIBUTING.md`](CONTRIBUTING.md) — where a new skill, checklist, or
house-rules change belongs by layer, and the objective verification gate
every addition must pass before it merges.
