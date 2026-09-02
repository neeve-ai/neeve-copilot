# Directory Redesign

**Status:** Proposal. No files moved.
**Companion docs:** `redesign-proposal.md` (the five moves, layer model, surfaces) ·
`implementation-plan.md` (v3, sequenced plan) · `superseded/connector/**` (a service
we decided not to build).
**Revised 2026-09-02** — connector dropped (D7); `cross-repo/` added (D8); `surfaces/`
simplified to one channel (D9); workspace provisioning promoted (D10); per-repo book
directory renamed `.help/` → `.neeve/` (D11); **harness made product-agnostic (D12), OT skill
retired (D13), bundle split rejected (D14)**.

This document translates the redesign into a filesystem. Every directory below exists to
make one decision legible; where a directory has no decision behind it, it is not here.

---

## 1. Design forces

The shape follows from what is already decided:

| Force | Source | Structural consequence |
|---|---|---|
| Mechanism, process, and skills have different owners, change rates, and CI bars | Move 4 | Three top-level homes, not one `neeve/` bag |
| Layers 04 + 03a live in git, read as files | **D5** | `foundation/` and `process/narrative/` — in the repo, read from the clone, never pushed ambient |
| Cross-repo knowledge has no home today | **D8** | `cross-repo/` — Layer 02½, SHA-pinned freshness |
| One surface, three populations | **D9** | `surfaces/` collapses to one real channel plus thin adapters |
| Layer 03b (executable rules) must stay in git | ADR-10 | `process/gates/` — new, and the centre of gravity |
| Storage ≠ delivery | Invariant A-9 | `foundation/` sits beside `ambient/` but **never renders into it** |
| The per-repo book is a namespace, not just docs | **D11** | `.help/` → `.neeve/`, name held in `framework.yaml`, dual-path migration |
| The harness names no product in a prompt | **D12** · invariant A-11 | No `foundation/products/`; no `products/` tree; product narrative lives in the product's planning workspace |
| Content and mechanism differ in owner and CI bar — but must be evaluated together | **D14** | **One repo**, boundary enforced by path-scoped CI + `CODEOWNERS` + a deleted glob, not by a repo split |
| Ambient context is a ~40-line budget, and its job is routing | Move 2, §6.2 | `ambient/` is tiny and partly **generated** |

A sixth, from the coupling audit: adding a tool today touches ~10 sites in `install.sh`.
Any structure that doesn't fix that has failed.

---

## 2. Target structure

```
neeve-copilot/
├── CODEOWNERS                      # D14 — practitioners own skills/ + evals/,
│                                   #       platform owns tools/ ambient/ surfaces/
├── framework.yaml                  # identity, marker token, tool targets, enabled disciplines
│                                   # + book_dir: .neeve  (D11 — a value, not a literal)
├── README.md  CONTRIBUTING.md  LICENSE
├── sync.sh                         # the one user-facing entry point
│
├── ambient/                        # ~40-line always-on plane (was base.md, 469 lines)
│   ├── core.md                     # identity · stakes · precedence — hand-written, budgeted
│   └── routing.md                  # GENERATED from registry/sources.yaml
│
├── foundation/                     # Layer 04 — READ AS A FILE, never pushed (A-9)
│   ├── identity.md                 # from foundation.md
│   ├── personas.md                 # market facts about Neeve, product-agnostic
│   └── customers.md
│                                   # NO products/ subdir — D12. Product narrative lives in
│                                   # that product's planning workspace .neeve/ book
│
├── disciplines/
│   ├── core/
│   │   ├── discipline.yaml
│   │   ├── ambient.md
│   │   └── references/             # production-consequence-and-gaps
│   ├── engineering/
│   │   ├── discipline.yaml
│   │   ├── ambient.md
│   │   └── references/             # quality-gates (narrative) · security
│   ├── product/
│   │   ├── discipline.yaml
│   │   ├── ambient.md
│   │   └── references/             # pm-lens · prd-system-of-record (narrative)
│   └── design/
│       ├── discipline.yaml         # NO ambient.md — deliberate, see §4
│       └── references/             # design-review · dls-usage-notes
│
├── skills/                         # ALL skills, flat. Membership declared in frontmatter.
│   ├── to-prd/  to-workitems/  to-spec/  implement-spec/  production-review/
│   └── repo-ask/  repo-intel/  debug-trace/  rca-retro-adr/  design-system/
│                                   # 10 skills, 3 renames (§5.4).
│                                   # ot-building-automation RETIRED — D13.
│                                   # No `products:` frontmatter field — D13.
│
├── process/
│   ├── narrative/                  # Layer 03a — why the loop is shaped this way
│   │   ├── design-loop.md          # from engineering-principles.md
│   │   └── what-good-looks-like.md
│   ├── workflow.yaml               # Layer 03b: stages · owners · artifacts · contracts
│   ├── gates/                      # Layer 03b — EXECUTABLE. Almost entirely new.
│   │   ├── quality-gates.yaml      # gate commands as data, per stack
│   │   └── artifact-rules.yaml     # validation predicates (create_prd, create_work_items…)
│   └── tiers.yaml                  # every rule → Blocked | Surfaced | Advised
│                                   # narrative + gates in one dir = one reviewable diff
│
├── cross-repo/                     # Layer 02½ — contracts and flows spanning repos (D8)
│   └── <topic>.md                  # each carries verified-against: <repo>: <sha>
│
├── registry/
│   ├── repos.yaml                  # was the 84-line pushed product-overview table
│   └── sources.yaml                # SoR map: domain → delivery → connector
│
├── agent/
│   └── neeve/AGENT.md              # single router, discipline-aware
│
├── surfaces/                       # projection layer — one directory per surface
│   ├── claude-code/
│   │   ├── build.py                # → dist/plugins/ + marketplace.json
│   │   ├── hooks/refresh-context.sh
│   │   └── install.sh              # marker-merge + settings surgery
│   └── adapters/                   # thin: codex · cursor · copilot · antigravity
│                                   # (no claude-ai/ — browser surface out of scope, D9)
│
├── templates/                      # per-workspace scaffolds
│   ├── book/                       # the .neeve/ OKF book skeleton (was .help/ — D11)
│   ├── workspace/.claude/settings.json   # D10 — auto-enables the discipline plugin
│   ├── hooks/pre-commit-context-sync
│   └── ci/{context-sync-check,integration-verify}.yml
│
├── tools/                          # THE MECHANISM
│   ├── render_ambient.py  render_agent.py  render_routing.py
│   ├── merge_house_rules.py  merge_session_hook.py  merge_default_agent.py
│   ├── init_workspace.sh           # D10 — code repo | planning repo | design space
│   ├── aggregate_books.py          # cron job, not a service (A-10)
│   ├── check_cross_repo_freshness.py
│   ├── check_consistency.py        # was check_org_sync.py, with real assertions
│   └── tests/
│
├── evals/                          # Move 5 — per-skill eval cases
│   └── <skill>/cases/
│
├── dist/                           # GENERATED — see §8 on whether this is committed
│   ├── plugins/<discipline>/
│   └── marketplace.json
│
└── docs/
    ├── architecture.md             # was neeve/README.md
    ├── setup.md                    # was products/robin/README.md (!)
    ├── adr/
    ├── migration/
    └── history/                    # plan.md, Feature-Reference.md
```

**No companion service repo.** The planned `neeve-context` was withdrawn under D7; its design
is preserved in `superseded/connector/**` so the reasoning stays findable.

---

## 3. What each top-level directory owns

| Directory | Owner | Change rate | CI bar | Contains |
|---|---|---|---|---|
| `ambient/` | Platform + leadership | Rarely | **High** — read on every request | ~40 lines, budgeted |
| `disciplines/` | Discipline leads | Quarterly | Medium | Packaging units + their references |
| `skills/` | Practitioners | **Weekly** | **Low — contribute freely** | Task playbooks |
| `process/` | Eng + PM leadership jointly | Quarterly | **High** — gates read it | Executable rules |
| `foundation/` | Leadership | Quarterly | Medium | Layer 04 prose |
| `cross-repo/` | Whoever traced it | On discovery | Medium — freshness-checked | Layer 02½ findings |
| `registry/` | Platform | On repo add | Medium | Repo + source-of-record maps |
| `surfaces/` | Platform | Rarely | High | Per-surface build + install |
| `templates/` | Platform | Rarely | Medium | Per-workspace scaffolds |
| `tools/` | Platform | Rarely | **High** | The mechanism |
| `evals/` | Practitioners | Weekly | Low | Eval cases |

The point of the table is the CI column. Today a skill tweak and an installer change pass
through the same eight-check gate, which simultaneously over-guards skills and under-guards
the mechanism. This split lets `skills/` and `evals/` be contributed casually while
`ambient/`, `process/`, and `tools/` stay carefully guarded.

**This table becomes actual CI configuration, not documentation (D14).** Path-scoped
workflows plus `CODEOWNERS` deliver the owner/change-rate separation that a separate bundle
repo would have delivered — without fragmenting the eval suite, which is why the bundle split
was rejected. See `ARCHITECTURE.md` D14.

---

## 4. The non-obvious choices

**`process/` is the centre of gravity, and it barely exists today.** Nothing in the current
repo is machine-readable process. This is the Layer 03b of the corrected model and it is
what makes the `Blocked` tier reachable at all, and with no connector it is now the *only*
enforcement mechanism — read by product-repo CI and pre-commit hooks. `tiers.yaml` is what turns the north-star metric (*what fraction
of rules are Blocked or Surfaced rather than Advised?*) from rhetoric into a number you can
compute in CI. **If only one new thing gets built, build this.**

**`ambient/routing.md` is generated from `registry/sources.yaml`.** The ambient block's job
is now routing rather than teaching, so derive it from the source-of-record map. A
hand-written routing block would claim knowledge lives somewhere it doesn't within a month;
a generated one cannot drift from the map it is built from.

**`products/` disappears entirely.** This is the least obvious consequence of the layer
decision. `products/robin/context/product-overview.md` splits three ways — narrative and
personas to **Robin's planning workspace book** (D12 — not this repo), the repo table to `registry/repos.yaml`, the local-dev runbook into
Robin's own `.neeve/` book. `products/robin/README.md`, which is currently the framework's
*actual* setup and troubleshooting doc misfiled inside a product directory, becomes
`docs/setup.md`. The two context fragments move to the discipline and skill that use them.
The one remaining skill is **retired, not relocated** (D13), and its domain content migrates
into the five repos it describes. Nothing is left, so the directory goes — and the
`products/*/skills` glob goes with it, closing the door structurally.

**`surfaces/` is the fix for the ~10-site problem.** Adding a sixth tool today means editing
a `global_path()` case statement, a usage string, five `DO_*` booleans, an arg parser,
auto-detect probes, five skill-install calls, five house-rules branches, two prune loops,
five agent-render branches, and a summary block. One directory per surface makes it one
addition.

**`cross-repo/` is a new top-level layer, not a subdirectory of something.** Cross-repo
knowledge — how auth flows across three repos, which repos share a contract — belonged
nowhere before: not derivable from any single repo's book, owned by no repo. It is the
content most prone to silent rot, so every entry carries `verified-against:` repo SHAs and a
scheduled check flags entries whose repos have moved past them. Without that contract it
becomes the wiki page that was accurate in March.

**`disciplines/design/` deliberately ships no `ambient.md`.** Design's stage gates don't
exist yet and can't be credibly invented; `discipline.yaml` makes `ambient` optional
precisely so this stays honest. Shipping invented always-on rules to designers is worse
than shipping none.

---

## 5. Old → new mapping

Complete for everything currently in the repo.

### Moves

| Today | Becomes | Note |
|---|---|---|
| `neeve/skills/<name>/` | `skills/<name>/` | + `disciplines:` frontmatter. **Three are renamed — §5.4** |
| ~~`neeve/products/robin/skills/ot-building-automation/`~~ | **retired — D13** | Domain content migrates into the five repos it describes, *then* the skill is deleted. Skills self-prune via `.neeve-manifest`; no `RETIRED_SKILLS` list needed |
| `neeve/agent/neeve/AGENT.md` | `agent/neeve/AGENT.md` | Name stays `neeve` (D2 — never rename) |
| `neeve/agent/README.md` | `docs/agents.md` | |
| `neeve/scripts/*.py` | `tools/*.py` | Dead ones deleted, see below |
| `neeve/scripts/test_*.py` | `tools/tests/` | Incl. `test_merge_default_agent.py`, currently not in CI |
| `neeve/templates/**` | `templates/**` | Content unchanged; add `templates/book/` |
| `neeve/hooks/refresh-context.sh` | `surfaces/claude-code/hooks/` | Also fix the `--all` scope escalation |
| `neeve/init-repo.sh` | `tools/init_workspace.sh` | Generalized: code repo **or** planning workspace |
| `neeve/CONTRIBUTING.md` | `CONTRIBUTING.md` | Root; fix the stale "§7 skills manifest" claim |
| `neeve/README.md` | `docs/architecture.md` | |
| `neeve/products/robin/README.md` | `docs/setup.md` | Framework doc, wrongly filed under a product |
| `sync_skills.sh` | `sync.sh` | Stays at root — user entry point |
| `setup-dev.sh` | `tools/setup-dev.sh` | |
| `plan.md`, `docs/Feature-Reference.md` | `docs/history/` | |
| `neeve/context/fragments/production-consequence-and-gaps.md` | `disciplines/core/references/` | Used by every discipline |
| `neeve/context/fragments/dls-usage-notes.md` *(under products/robin)* | `disciplines/design/references/` | |
| `neeve/context/fragments/ot-domain-notes.md` *(under products/robin)* | the OT repos' `.neeve/` books | Travels with the rest of the D13 migration; the skill that consumed it is retired |
| `neeve/references/design-review.md` | `disciplines/design/references/` | |
| `neeve/skills/code-review/references/security.md` | `disciplines/engineering/references/security.md` | Canonical shouldn't live inside one consumer |

### Splits — the interesting half

| Today | Splits into | Why |
|---|---|---|
| `neeve/context/base.md` (469 lines) | `ambient/core.md` (~40) + `disciplines/*/ambient.md` | Move 2 + discipline scoping |
| `neeve/foundation.md` | `foundation/{identity,personas,customers}.md` | **D5** — stays in the repo, restructured, read as a file |
| `neeve/engineering-principles.md` | narrative → `process/narrative/` (03a) · enforceable items → `process/gates/` (03b) · PRD/Scoping §§ → `disciplines/product/references/` · Design §§ → `disciplines/design/references/` | ADR-10 + discipline split. All four destinations now in one repo |
| `neeve/references/quality-gates.md` | "why" → `disciplines/engineering/references/` · **the commands** → `process/gates/quality-gates.yaml` | Move 1: the gate becomes executable, not described |
| `neeve/references/pm-lens.md` | checklist prose → `disciplines/product/references/` · checkable items → `process/gates/artifact-rules.yaml` | Feeds `create_prd` validation |
| `neeve/references/prd-system-of-record.md` | narrative → `disciplines/product/references/` · Status lifecycle + write-back rule → `process/workflow.yaml` | The lifecycle is data |
| `neeve/products/robin/context/product-overview.md` | narrative → **Robin's planning workspace `.neeve/` book** (D12, *not* the framework) · repo table → `registry/repos.yaml` · local-dev runbook → Robin's own code-repo book | Still three-way, but only one destination is in this repo — and it is data, not prose |
| `neeve/install.sh` (495 lines) | `surfaces/*/install.sh` + `tools/` | Fixes the ~10-site problem |
| `neeve/scripts/skills_sync.sh` | Retired for Claude Code (plugins replace it); kept for `surfaces/adapters/` | Plugin format replaces zip packaging on the primary surface |

### Deletions

| Deleted | Reason |
|---|---|
| `neeve/prompts/` (9 files) + `scripts/prompts_sync.sh` (89 lines) | Validated by CI, **installed nowhere** |
| `neeve/context/fragments/{code-review,spec}-review-checklist.md` | Their render functions are dead in production; fold into the owning skill's `references/` |
| `neeve/scripts/shared_refs_sync.sh` | Existed to duplicate `quality-gates.md` into 6 skills; plugin bundling removes the need |
| `context_render.py`'s `OUTPUT_FILES` + 4 of 6 render functions | Dead; kept alive only by their own tests |
| `neeve/products/**` | Dissolves completely — D13 removed the last thing in it. The `products/*/skills` glob is deleted from **all three** discovery implementations (`install.sh:14-22`, `skills_sync.sh:9-12`, `check_org_sync.py:38-43`), so a product skill has nowhere to go |
| The `neeve/` wrapper directory | Redundant nesting inside `neeve-copilot/` |

### 5.4 Renames — three, each justified

**Do it in step 4 or carry a migration.** Plugin marketplaces support a `renames` field, so a
later rename is *possible* — but only if the migration entry exists, and `.neeve-manifest`
prunes installed skills by directory name (§5.5). Step 4 is already rewriting every path, so
the marginal cost there is near zero.

*Reduced pressure since 2026-09-02:* the original urgency came from claude.ai's
organization-provisioned skills, which have no rename mechanism at all. With the browser
surface out of scope (D9), renaming is a quality decision rather than a deadline.

| Old | New | Justification |
|---|---|---|
| `to-erd` | **`to-workitems`** | ERD universally reads as *Entity Relationship Diagram*. The skill's own description spends a clause disclaiming this — *"Not to be confused with a database Entity Relationship Diagram."* **A name that needs a disclaimer inside its own description is a bad name**, and that disclaimer is doing work a better name would make unnecessary. |
| `neeve-dls` | **`design-system`** | Org name embedded in a skill name; namespaced it stutters as `/neeve-design:neeve-dls`. Already structural in `shared_refs_sync.sh:30` and `agents/openai.yaml:4`, both being touched anyway. |
| `code-review` | **`production-review`** | Collides with Claude Code's **built-in** `/code-review`. Namespacing fixes the typed form but not description-based auto-invocation, and two skills with near-identical descriptions competing is a real degradation. The new name also matches its actual emphasis: production-readiness, contracts, deployability. |

**Kept, with reasons:** `to-prd` / `to-spec` — the `to-` prefix reads as transformation and
groups the family; that is a virtue. `implement-spec`, `repo-ask`, `repo-intel`,
(`repo-*` stays correct because those skills remain engineering-only; the workspace
generalization does not reach them). `debug-trace` — the
name undersells it, since its own description calls it *"the maximal-depth grounding
discipline"* rather than debugging, but renaming for elegance is not worth structural churn.

**Ruled out: discipline prefixes** (`product-to-prd`, `eng-code-review`). Plugin namespacing
already provides scoping, and a prefix would force a false single home on exactly the skills
that prove multi-membership — `to-workitems` is product *and* engineering, `design-system` is
design *and* engineering.

**Resolved: keep `rca-retro-adr` merged.** Three acronyms welded together because it genuinely
does three things. The case for splitting rested mainly on claude.ai's 200-character
description cap making all three modes hard to describe — and with the browser surface out of
scope, that constraint is gone. Its ~530-character description is fine on the plugin surface.
Splitting would triple the maintenance for no remaining benefit.

### 5.5 Per-file changes each rename forces

Beyond the ~400 citations already breaking in step 4:

| File | What breaks |
|---|---|
| `neeve/scripts/shared_refs_sync.sh:30` | Hardcoded `skills/neeve-dls/references/quality-gates.md` in `DESTINATIONS`. Fails `check` → fails `pack` → aborts install |
| `.github/workflows/release.yml` | Smoke test asserts `code-review`, `to-spec`, `implement-spec` by name |
| `neeve/scripts/check_org_sync.py` | Matches literal `` `<name>` `` against the routing table; a rename fails CI until `AGENT.md` is updated |
| `neeve/skills/neeve-dls/agents/openai.yaml:4` | `default_prompt: "Use $neeve-dls to ..."` must match the directory name |
| `.neeve-manifest` / `prune_stale_skills` | **Prunes by directory name.** A rename without a migration entry leaves the old skill installed *forever* on every machine that synced before the change — same failure class as the `RETIRED_AGENTS` list, and the one most likely to be missed |
| `agent/neeve/AGENT.md` | Routing table entries |
| `evals/<skill>/` | Directory names, once evals exist |

The `.neeve-manifest` row is the only one that fails **silently**. Everything else fails
loudly in CI. Add the three old names to a migration list in the same commit.

### 5.6 `.help/` → `.neeve/` — the rename that reaches other repos

Unlike §5.4's skill renames, this one lives in **product repos**, so the framework's own path
rewrite (step 4) does not cover it. Full rationale: `ARCHITECTURE.md` D11.

| Location | Change | Cost |
|---|---|---|
| `templates/hooks/pre-commit-context-sync:85` | `HELP_DIR = REPO / ".help"` → resolve `book_dir` from config, `.neeve/` then `.help/` fallback | **One line.** The other 22 hits in this file are docstrings and messages |
| `init-repo.sh` → `tools/init_workspace.sh` | Emit `.neeve/` for new workspaces | 42 hits, but this file is rewritten in P7 anyway — marginal cost ≈ zero |
| `templates/ci/context-sync-check.yml` | One comment | Trivial |
| Skills · ambient · docs | ~40 prose citations | Find-and-replace |
| `framework.yaml` | New `book_dir: .neeve` key | The name becomes a value, not a literal |
| **~16 product repos** | `git mv .help .neeve` + reinstall hook + **update `.dockerignore` and `.gitignore`** | One self-contained PR each. **This is the whole real cost** |

**Per-repo migration checklist** — the third item is the one that bites:

1. `git mv .help .neeve`
2. Reinstall the hook (`init_workspace.sh` on an already-initialised repo is safe to re-run)
3. **Update `.dockerignore` and `.gitignore`.** The book lives in a dot-directory precisely so
   `.dockerignore` can exclude it; a missed entry **ships the book into a container image**
4. Commit — atomic, because each repo carries its own copy of the hook, so directory and hook
   cannot drift apart

**No flag day.** Dual-path resolution means an untouched repo keeps working indefinitely.
Remove the fallback once all sixteen have migrated.

---

## 6. New content that must be authored

Nothing below exists today. Ordered by how much unblocks.

| Path | Unblocks | Notes |
|---|---|---|
| `registry/repos.yaml` | Connector Phase A | Mechanical extraction from the existing 16-repo table |
| `registry/sources.yaml` | `ambient/routing.md` generation | The SoR map from `redesign-proposal.md` §6.1 |
| `process/gates/quality-gates.yaml` | The `Blocked` tier | Convert 133 lines of prose into commands-as-data |
| `process/gates/artifact-rules.yaml` | `create_prd` validators | From `pm-lens.md` items 1–3 |
| `process/workflow.yaml` | Stage contracts, PRD lifecycle | Ends the five-way Design Loop duplication |
| `process/tiers.yaml` | The north-star metric | Every rule tagged; an untagged rule is a review finding |
| `framework.yaml` | Identity in one place | Marker token, tool targets, enabled disciplines |
| `ambient/core.md` | Move 2 | **Editorial, not mechanical** — budget real writing time |
| `disciplines/*/discipline.yaml` | Discipline packaging | Glob-discovered, never a hardcoded list |
| `disciplines/product/ambient.md` | PM rollout | ≤80 lines |
| `cross-repo/` + freshness check | Layer 02½ (D8) | Reuses the manifest-hash pattern |
| `templates/workspace/.claude/settings.json` | Onboarding (D10) | Auto-enables the right discipline plugin on folder trust |
| `CODEOWNERS` | D14 | Practitioners own `skills/`+`evals/`; platform owns `tools/`, `ambient/`, `surfaces/` |
| Path-scoped CI workflows | D14 | Makes §3's CI-bar column real instead of documentation |
| `process/gates/product-names.yaml` (denylist) | D12 | Fails the build on a product name in `ambient/`, `skills/`, or `agent/`; passes in `registry/` |
| `evals/<skill>/cases/` | Move 5 | Design for `claude plugin eval`; don't depend on it yet |

---

## 7. Mechanical breakage inventory

Paths change, so these break and must be fixed in the same change:

- **~400 markdown citations** of the form `` `neeve/references/...` `` across skills, docs, and the agent.
- **`.github/workflows/ci.yml`** — all 18 path references; also add `test_merge_default_agent.py`, which currently never runs.
- **`.github/workflows/release.yml`** — 29 occurrences; the tag trigger is `robin-skills-v*`, so **no release fires under any other name**, and it copies a product README as the bundle README.
- **`.git-hooks/post-commit`** — `SKILLS_PATH="neeve/(products/[^/]+/)?skills"` regex and a hardcoded `products/robin/README.md` path.
- **`.gitignore`** — `neeve/dist/` → `dist/` (and see §8 on whether it stays ignored).
- **`.help/` → `.neeve/`** — one constant in the committed hook, plus every product repo's
  `.dockerignore`/`.gitignore` (§5.6). Not covered by the framework-side path rewrite.
- **The `products/*/skills` glob** — deleted from three independent discovery implementations
  (D13). Each currently walks both roots; after this they walk one.
- **`to-prd`'s domain rules** — Core Rule 2's commercial-real-estate mandate and the hardcoded
  `robin-adr/prds/` write path (D12). The rule keeps its teeth in generalised form: *name a
  persona from the org's foundation, refuse a placeholder.*
- **Test assertions** — 27 brand/path strings baked into `test_context_render.py`, `test_merge_default_agent.py`, `test_merge_house_rules.py`. These fail first and are a useful change detector.

Python scripts themselves are safe: they resolve `ROOT` via `Path(__file__).resolve().parents[1]`.

---

## 8. Two boundary decisions

### No service repo to boundary

The planned `neeve-context` service was withdrawn (D7): with every population holding a git
clone, its read plane became a file read and its write plane became a pre-commit linter. So
the monorepo-versus-split question is moot, and `process/` + `registry/` are consumed
directly rather than through a versioned contracts package.

**What survives from that analysis** is the reason it was tempting: `process/gates/` is read
by two consumers — product-repo CI and the per-workspace pre-commit hook. It reaches them by
**code-gen** (§2 `tools/`), not by network. That keeps invariant A-3 intact: a gate reads its
rulebook with no human present to authenticate.

### `dist/`: committed, with a drift check

Marketplace entries using relative sources require the built plugins to be committed, but
`.gitignore` currently excludes `neeve/dist/`. Recommendation: commit `dist/` and add a CI
drift check, mirroring the existing generated-copy pattern. **Verify first** whether a
marketplace entry can reference a subdirectory of its own repo — if it can, that is
strictly better and `dist/` stays ignored.

---

## 9. Migration sequence

Structure follows the revised roadmap, not the reverse.

| Step | Does | Checkpoint |
|---|---|---|
| **0** | Safety fixes in place (truncate bug, refresh-loop scope, uninstall path, CI gap) | Existing CI green + 2 new regression tests |
| **1** | Create `registry/repos.yaml` + `registry/sources.yaml` | Connector Phase A can start; nothing else moves yet |
| **2** | Create `process/**` from existing prose | `tiers.yaml` computes a real Blocked/Surfaced/Advised ratio |
| **3** | `ambient/` shrink: `base.md` → `core.md` + discipline `ambient.md` | Product payload contains no `mypy`; any discipline ≤220 lines |
| **4** | Flatten `neeve/`, move `skills/`, **apply the three renames**, add `disciplines:` frontmatter — one commit | Fix all §7 + §5.5 breakage here. One painful commit, not five. **Last chance to rename before publish** |
| **5** | Restructure `foundation.md` → `foundation/`, 03a narrative → `process/narrative/`, add `cross-repo/` + its freshness check; **migrate OT content into its five repos' books, then delete the skill (D13)**; dissolve `products/` and delete the glob | **A move, not an extraction.** A-9 check and the D12 denylist check land in CI here |
| **6** | `surfaces/` + `dist/` + `templates/workspace/`; emit `.neeve/` for new workspaces with `.help/` fallback (D11) | Plugin drift check green; throwaway-`$HOME` smoke test; **a non-engineer reaches a first task from a clean machine** |
| **6b** | Migrate the ~16 product repos to `.neeve/`, one PR each, then drop the fallback | Each repo: book moved, hook reinstalled, ignore files updated, image build verified clean |
| **7** | `evals/` | At least one case per PM-facing skill |

**Do steps 4 and 5 in that order.** Flattening first means the content migration happens
against stable paths; reversing it means doing the path fixes twice.

---

## 10. Open questions

1. **Does Robin still do Niagara/WebCTRL work?** If the work continues and only the *skill
   mechanism* is retiring, the 12.9 KB migrates into the five repos' books first (D13). If the
   work itself has stopped, delete outright. **The only item gating D13.**
2. **Where does the book aggregation job run** — a cron in CI, or a local `sync` step? It
   produces a searchable local book set across ~16 repos. A job, not a service (A-10).
3. **`dist/` committed?** Depends on whether a marketplace entry can point at a subdirectory
   of its own repo — unverified.
4. **Where does `HOW-TO-USE.md` land?** It spans setup, per-tool notes, and context
   management — three audiences. Probably splits into `docs/setup.md` and
   `docs/architecture.md`, but it is the most-read doc in the repo and worth a deliberate
   rewrite rather than a move.
5. **Does `ambient/core.md` need a per-surface variant?** Copilot and Codex do not
   auto-route to agents, so the ambient block may be carrying more weight there than in
   Claude Code. A uniform ~40-line budget may be wrong per surface.

*Closed by D12/D13:* whether `disciplines/` needs its own `products:` axis — no. `products/`
dissolved, the skill frontmatter field is dropped, and product scoping is now a property of
the workspace you are in rather than of a skill.
