# How To Use Neeve Copilot

Three things to know: how to use it in your AI tool, how to set up a repo,
and how the context stays correct as everything changes. Architecture
deep-dive: [`neeve/README.md`](neeve/README.md).

---

## 1. Set up your machine (once)

```bash
git clone git@github.com:neeve-ai/neeve-copilot.git ~/Projects/src/neeve/neeve-copilot
bash ~/Projects/src/neeve/neeve-copilot/sync_skills.sh
```

This installs the skills, the house rules, and the `neeve` agent into every
AI tool on your machine — globally, nothing written into any project.
Re-run `sync_skills.sh` any time to refresh.

**The everyday rule: ask for what you want in plain words — the matching
skill loads itself.**

| You say | Skill that answers |
|---|---|
| "write a PRD for X" | `to-prd` |
| "break this PRD into work items" | `to-erd` |
| "map this repo" | `repo-intel` |
| "how does X work" / "why does X fail" | `repo-ask` |
| "spec this" | `to-spec` |
| "implement task N" | `implement-spec` |
| "review this PR" | `code-review` |
| "update this DLS component" | `neeve-dls` |
| Niagara / BQL / WebCTRL work | `ot-building-automation` |
| "trace this thoroughly" | `debug-trace` |

Together they form the Design Loop:
`to-prd → to-erd → to-spec → implement-spec → code-review → merge → CI`,
looping back to the next feature. A small bug fix starts at `to-spec` —
not every change needs every stage.

Stuck or unsure what to use? Ask the `neeve` agent: *"is my setup
working?"*, *"which skill do I use for X?"*

---

## 2. Per-tool notes

The skills behave the same everywhere. Only invocation details differ:

| Tool | Invoke a skill | The `neeve` agent | House rules | Staying up to date |
|---|---|---|---|---|
| **Claude Code** | auto, or `/skill-name` | auto, or `@agent-neeve` | merged into `~/.claude/CLAUDE.md` (your own content untouched) | **automatic** — a session hook pulls updates for you |
| **GitHub Copilot** (VS Code, agent mode) | auto, or `/skill-name` | pick from the **agent picker** (no auto-routing) | auto-loaded from `~/.copilot/instructions/` | re-run `sync_skills.sh` |
| **Cursor** | auto, or `/skill-name` | auto (installed as a skill) | one-time paste into Settings → User Rules (installer prints it) | re-run `sync_skills.sh` |
| **Codex CLI** | `$skill-name` | `/agent` (explicit only) | merged into `~/.codex/AGENTS.md` | re-run `sync_skills.sh` |
| **Antigravity 2.0** | auto, or `@skills` | auto (installed as a skill) | merged into `~/.gemini/AGENTS.md` | re-run `sync_skills.sh` |

---

## 3. Set up a repo (once per repo, after cloning)

Every product repo carries its own knowledge book — three files an AI agent
reads before touching code. The book and its freshness hook are **committed
to that repo itself** (not to neeve-copilot), so everyone who clones the
repo gets them automatically.

```bash
cd <your-cloned-repo>
bash ~/Projects/src/neeve/neeve-copilot/neeve/init-repo.sh
```

This creates:

| File | What it holds |
|---|---|
| `introduction.md` | The README *for agents*: stack, how the repo wires into the product, make/docker commands, how it deploys |
| `index.md` | Table of contents: each functional area → where it lives |
| `appendix.md` | Every public class/function: purpose, dependencies, what breaks if you change it |
| `.githooks/pre-commit` | A fast, deterministic check that warns when the book falls out of date |

Then fill the book from real code: open the repo in your AI tool and say
**"map this repo"**. The `repo-intel` skill replaces every TODO marker with
scanned, cited content.

Finally, commit it in that repo like any change:

```bash
git checkout -b chore/okf-book-init
git add introduction.md index.md appendix.md .githooks/
git commit -m "chore: init knowledge book + freshness hook"
```

From then on the book evolves with the code — the hook tells you when a
commit needs a book update, and it rides along in the same PR.

Optional:
- `init-repo.sh --with-ci` also adds two CI workflows: one that blocks a PR
  if the book is stale, one for integration tests (edit it to the repo's
  real test command — it fails on purpose until you do).
- The hook only *warns* by default. Once trusted, make it blocking:
  `git config neeve.contextsync.block true`.

Works the same for a brand-new repo (thin skeleton on day 1) and an old one
(full scan).

---

## 4. How context is managed and scaled

Context lives in four layers — each one small, owned, and checked:

| Layer | What | Lives in | Kept honest by |
|---|---|---|---|
| Company foundation | What Neeve is, products, customers, personas | neeve-copilot → installed as house rules | Re-rendered on every install; CI citation checks |
| Engineering principles | SDLC principles, quality gates, security rules | neeve-copilot → house rules + skills | One canonical file; CI fails if any copy drifts |
| Repo knowledge | The book: `introduction.md` / `index.md` / `appendix.md` | **each repo itself** | Pre-commit hook + CI check on every change |
| Your own overrides | Personal instructions and settings | your machine only | Yours — the installer never touches them |

Three rules make it scale:

1. **One fact, one place.** Every shared doc has a single canonical source;
   any copies are generated and CI-diffed against it. Editing a copy fails
   the build by design.
2. **Freshness is mechanized, not remembered.** Machines self-update
   (Claude Code) or refresh with one command; the repo book is checked on
   every commit by a plain script — no model call, no token cost; the
   framework's own CI fails if a new skill ships without the agent routing
   to it.
3. **Scripts detect drift, models fix it.** The hook only flags what a
   script can prove (a hash changed, a symbol is undocumented). Rewriting
   the narrative is always an explicit `repo-intel` run — so you pay for
   regeneration only when something actually drifted.

Adding things stays cheap: a new engineer is one command; a new repo is one
registration file + `init-repo.sh`; a new skill is one directory (CI forces
it into the agent's routing table); a new product is one folder.

**Why it's built this way:** the failure this prevents is an AI agent
confidently editing code — code that often sits between an operator and
real building equipment — using a stale map of the repo. Every mechanism
above makes staleness *loud* (a warning, a red check, a TODO marker)
instead of silent.

**Known gaps:** tools other than Claude Code refresh only when you re-run
`sync_skills.sh`; the hook's
symbol detection is exact for Python but conservative for TypeScript/Go
(one reason it starts warn-only); and the repo-setup flow should be
piloted on one small repo before rolling out everywhere.
