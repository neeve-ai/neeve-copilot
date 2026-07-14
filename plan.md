# Neeve-Copilot Restructure — Aligned to the "Agentic Coding" Deck

## Context

The deck (`Agentic Coding.pdf`) is Neeve's own stated target architecture, not a
generic best-practice writeup — this plan re-derives the restructure from *its*
vocabulary and structure instead of an invented framing, and fills the gaps the
deck exposes in the current `neeve-copilot` repo. Six named problems must each
have a concrete answer in the new structure (not just be "kept in mind"):

| # | Problem (deck) | Where this plan answers it |
|---|---|---|
| 1 | Code Quality consistency across models/agents | Single unified `neeve` agent + one canonical quality-gates source, so every harness enforces the same bar |
| 2 | Context Bloat vs insufficient context | 4-Layer Context stack (below) — each layer loads only what that scope needs; repo-level book keeps the always-on slice small |
| 3 | Code Evolution / diminishing ROI on token spend | Repo-level book stays generated/refreshed (existing `refresh-context.sh` SessionStart hook), not hand-maintained prose that rots |
| 4 | Process Enforcement (CI/pipeline, make commands) | New Harness/Hooks pillar — CI workflow templates + local `make` targets wired to hooks, not just voluntary instructions |
| 5 | Greenfield/Brownfield asymmetry | Repo-level book render (`context_render.py`) is the same day-1 step for new or existing repos; brownfield gets `repo-intel` to bootstrap the book from real code |
| 6 | Consequential Engineering | Already-adopted "state production consequence + gaps" discipline stays load-bearing — carried into `engineering-principles.md` (layer 03), not diluted |

**Scope note (supersedes an earlier narrower answer):** the deck's "Proposed
Architecture" explicitly includes a CI/hooks harness and an 8-stage loop with
acceptance contracts, not just a directory/agent restructure. This plan takes
that on, scoped to *this repo's own deliverables* (templates, hook scripts,
canonical docs, the agent, CI for `neeve-copilot` itself). It does **not**
build managed-settings/policy-tier infrastructure for every consuming repo —
that's a per-product-repo rollout that consumes what this plan produces.

## Positioning vs "Existing Approaches" (deck slide 3)

This restructure evolves **Neeve Copilot** (the current repo), not a rewrite
against a different base:
- Takes spec-kit's discipline (concrete scenarios before code) — already
  `to-spec`'s job; kept and reinforced with the deck's explicit acceptance
  contracts.
- Takes Ruflo's idea of a guardrail-carrying execution layer, but deliberately
  **not** its 100+-agent swarm model — the user has already fixed this as
  **one unified agent** for Claude Code + GitHub Copilot compatibility; skills
  carry the specialization instead of a swarm of agents.
- The older "Neeve Dev AI Framework" (32 prompt files/12 scripts/4 hooks,
  purely voluntary, no runtime loop) is the predecessor this replaces —
  confirm during migration whether any of its 32 files contain content not
  already absorbed into `neeve-copilot`'s skills/context before deleting it.

## Proposed Architecture, Pillar 1 — 4 Layers of Context

Deck's pyramid, base = broadest/most stable, apex = narrowest/most volatile.
Naming and scope taken directly from the deck (not renamed to "tiers"):

| Layer | Deck definition | Canonical source in this repo | Rendered into |
|---|---|---|---|
| 04. Neeve Foundation | What is Neeve? Why? Culture? Product? Customers, user personas | NEW `neeve/foundation.md` (company identity, mission, culture) + `products/*/product-overview.md` (per-product portfolio/persona detail, e.g. Robin) | Always-on digest folded into house rules |
| 03. Engineering Principles | Best practices: security, engineering style, etc. | `neeve/engineering-principles.md` (merges current `org/PRINCIPLES.md`'s engineering-specific sections) + `neeve/references/security.md` + `neeve/references/quality-gates.md` as its cited deep references | House rules body; cited by skills |
| 02. Repository-Level Context | "Following book analogy for maintaining context efficiently via OKF" | **Three files checked into the target repo itself** (not a global render) — see below | Read directly by any harness pointed at that repo; imported by the thin `AGENTS.md`/`CLAUDE.md` pointer file that still carries Layers 03/04 house rules |
| 01. Custom & User Context | Developer-local execution instructions, prompt overrides | Not a repo directory — documented behavior: content outside `BEGIN/END NEEVE` markers in `~/.claude/CLAUDE.md`, `CLAUDE.local.md`, `settings.local.json` | Never touched by the installer |

**OKF (Open Knowledge Format):** plain markdown only, no tool-proprietary
syntax, so the same three files are readable by Claude Code, Copilot, Codex,
Cursor, Antigravity without translation.

### Layer 02, concretely — the per-repo OKF book

This was the gap: a repo-level book only means something if it's a real,
checked-in, scaling mechanism — not a render concept. Three files live at the
root of **every target product repo** (robin-ai, robin-web, dls-neeve, etc.),
committed to that repo's own git history, distinct from the human `README.md`:

- **`introduction.md`** — the contextual README *for agents*: tech stack &
  versions, how this repo wires into the rest of the product (what it calls,
  what calls it — NATS/HTTP/MCP), pointer to the OpenAPI contract if it's a
  backend, `make` targets and what each does, Dockerfile/docker-compose and
  how local dev spins up, how it deploys (Helm chart if any). Small, always
  read first.
- **`index.md`** — the book's table of contents: functional areas mapped to
  where they live ("Auth → `src/auth/**`, entrypoint `src/auth/middleware.ts`,
  see `appendix.md#AuthService`"), organized by feature/domain so an agent
  jumps straight to the right place instead of grepping cold.
- **`appendix.md`** — the deep reference: every public method/class with its
  **purpose**, **dependencies** (what it calls / what calls it), and
  **impact if changed** (blast radius — which other modules or services
  break). The expensive, highest-value-when-correct file.

**Bootstrap:** the `repo-intel` skill's deliverable changes from a single
`CONTEXT.md` to these three files. Brownfield repos get a full scan on first
run; greenfield repos get a thin skeleton on day 1 (same command, same skill,
answers the deck's Greenfield/Brownfield asymmetry problem directly).

**Keeping it current — the mechanism that was missing:** a **pre-commit hook**
template shipped from this framework
(`neeve/templates/hooks/pre-commit-context-sync`), installed into each target
repo via a committed `.githooks/pre-commit` + `git config core.hooksPath
.githooks` (committed, so it applies for every clone, not just the installer's
machine):
- **Deterministic, no model call in the hot path.** Symbol extraction
  (ctags/tree-sitter appropriate to the repo's declared stack) diffs current
  method/class signatures against `appendix.md`'s tracked table; auto-patches
  mechanical fields (signature, file:line, statically-found callers/callees).
  Any new/changed symbol without a purpose/impact note gets stamped
  `TODO(purpose)` in the diff — visible to the reviewer, never silently stale
  (same discipline as the CLAUDE.md house rule: a gap is a line item, not a
  silence).
- Hashes the files that drive `introduction.md` (package manifest, Dockerfile,
  Makefile, OpenAPI spec path) against a hash stored in its frontmatter; if
  they changed, the hook fails with "run `repo-intel --refresh` before
  committing" (configurable to warn-only).
- Structural diff for `index.md`: new top-level modules not yet indexed are
  flagged.
- Because `--no-verify` can bypass a local hook, the **same check also runs
  as a required CI status check** (ties into Pillar 2's Agent CI Guardrails)
  — so drift can't merge even if the local hook was skipped.
- Full narrative regeneration (the judgment-requiring parts — the "why" in
  `introduction.md`, chapter grouping in `index.md`, purpose/impact prose in
  `appendix.md`) stays an explicit, agent-assisted `repo-intel` invocation,
  never automatic inside the commit hook. This keeps the hot path fast and
  keeps LLM judgment where it belongs, directly answering Problem 3 (Code
  Evolution / token ROI) — the book doesn't rot into hand-maintained prose,
  and it doesn't burn tokens on every commit either.

## Proposed Architecture, Pillar 2 — Harness with Hooks

Deck: "Git & CI/CD lifecycle event triggers and validations" +
"Define Harness: CI & Agent Instructions" (4 sub-items). Concrete deliverables:

1. **Spec & SOLID Principles** — `to-spec`/`implement-spec` already assert this
   in prose; add a machine-checkable line item to `references/quality-gates.md`:
   no `implement-spec` run may start without a linked spec section reference
   (the skill already requires this — make it a literal checklist line the
   `code-review` skill checks for on PRs, not just a to-spec-time instruction).
2. **Automated Unit Testing (≥95%)** — already the number in
   `references/quality-gates.md` (verified: `--cov-fail-under=95` for Python,
   equivalent for TS). No new number; make sure it's the single cited source
   everywhere instead of restated.
3. **Integration Verification** — NEW: a template GitHub Actions job
   (`neeve/templates/ci/integration-verify.yml`) that consuming repos copy in,
   running each repo's declared integration/system test command (sourced from
  the repo's own documented test command) on every PR. This is new scope
   this repo now owns as a template, not a live workflow in every product repo.
4. **Repo-book freshness (`pre-commit-context-sync`)** — the Layer 02
   mechanism described above: a committed pre-commit hook per target repo
   that deterministically flags/patches `appendix.md`/`index.md`/
   `introduction.md` drift, backed by the same check as a required CI status
   so `--no-verify` can't silently merge stale context.
5. **Agent CI Guardrails** — the SessionStart `refresh-context.sh` hook
   already auto-injects context; add a companion **Stop-hook template**
   (`neeve/hooks-src/pre-merge-checklist.sh`, Claude-Code-only, best-effort
   elsewhere) that runs the quality-gates checklist locally before the agent
   reports a task done — mirroring "checklist-based quality audits before
   merging code" without requiring a runtime control loop (still no model
   invocation from inside the hook, consistent with "voluntary protocol,
   deterministic check" — the check is deterministic bash/make, not an LLM call).

This directly answers Problem 4 (Process Enforcement) and half of Problem 1
(Code Quality) — enforcement moves from "the agent should remember to..." to
a script that fails loudly.

## Proposed Architecture, Pillar 3 — Designing Loops

Deck's 8-stage loop, each with an **Acceptance Contract** — this is the gap
the current skill set only partially covers. Mapping:

| # | Stage | Acceptance Contract (deck) | Current owner | Gap / decision |
|---|---|---|---|---|
| 1 | PRD | Clear objectives & user persona defined | `to-prd` skill (converted from agent, see below) | none |
| 2 | Design (Architecture) | Component & data-flow diagrams locked | **none today** | **Gap.** Do not add a 9th skill. Fold in as an explicit first phase of `to-spec` — `to-spec/SKILL.md` gains a "Design" sub-step that must produce/lock a component & data-flow sketch before the spec's requirements section, with its own checkable acceptance line. Revisit splitting it out only if `to-spec` grows unwieldy. |
| 3 | ERD | Schema structure & relations validated | `to-erd` skill (converted from agent) | none |
| 4 | Spec | SOLID design patterns explicitly mapped | `to-spec` | Add explicit SOLID-mapping checklist line to `to-spec`'s acceptance criteria section (currently implied, not itemized) |
| 5 | Implement | Executable code, >95% unit coverage | `implement-spec` | none — already the enforced number |
| 6 | Code Review | Pre-merge quality checklist verified | `code-review` skill | none |
| 7 | Merge | Conflicts resolved & harness hooks validated | **process, not a skill** | The unified agent's role here is supervisory only: verify the Stop-hook checklist (Pillar 2 item 4) passed before advising merge; never merges itself without the user's go-ahead (existing "risky action" rule already covers this) |
| 8 | CI Pass | Continuous sandbox test evaluations passed | **process, not a skill** | Same supervisory role; agent points at the Integration Verification workflow template (Pillar 2 item 3) result, doesn't fabricate a pass |

The dotted line from stage 8 back to stage 1 in the deck is the **outer
loop**: CI Pass on one feature is the re-entry point for the next PRD. The
unified agent's routing table is this table, not a separate invention.

## The unified `neeve` agent

One agent, compatible with Claude Code and GitHub Copilot (Copilot has no
subagents — the agent routes to *skills*, never delegates to sub-agents).
Source: `neeve/agent-src/neeve/AGENT.md`, same frontmatter dialect as today
(`name` / folded `description` / `tools: [read, write, search, bash]`) so
`agents_render.py` needs no parser changes. Renders to
`~/.claude/agents/neeve.md` and `~/.copilot/agents/neeve.agent.md`
(best-effort Codex TOML / Cursor-Antigravity skill-fallback unchanged).

Body:
1. **Identity** (~10 lines) — cites `foundation.md` + `engineering-principles.md`, doesn't restate them.
2. **Operating rule** — skills are the capability unit; the agent names/invokes a skill and supervises, never improvises a rubric a skill owns.
3. **Routing table = the 8-stage loop table above**, each row naming the skill and its acceptance contract; escalation to `debug-trace` when a step needs exhaustive tracing/research; mandatory `code-review/references/security.md` pass when a change touches auth/tenancy/network/credentials.
4. **Setup/onboarding section** (absorbs `neeve-guide`): prerequisites check, install verification per tool.
5. **Per-tool note**: Claude auto-trigger vs Copilot agent picker; skills still auto-trigger in Copilot without the agent being invoked directly.

**Fold map for the 8 retired specialist agents** (unchanged reasoning from
prior analysis, restated for completeness):

| Agent | Destination |
|---|---|
| `to-prd`, `to-erd` | converted to skills — improves Copilot auto-trigger vs picker-only agents |
| `neeve-guide` | setup half → agent's Setup section; triage half → routing table |
| `repo-guide` | retired; covered by the per-repo `introduction.md`/`index.md` + `repo-ask`/`repo-intel` |
| `neeve-reviewer` | merged into `code-review/references/principles.md` |
| `neeve-security-partner` | merged into `references/security.md` (keep the 4 headings `check_org_sync.py` already asserts) |
| `neeve-pm-partner` | `references/pm-lens.md`, referenced from `to-spec` (stage 4) + `to-prd` (stage 1) |
| `neeve-design-partner` | `references/design-review.md`, referenced from `neeve-dls` + code-review routing |
| `neeve-ot-specialist` (placeholder) | deleted; `ot-building-automation` skill is the carrier |

## Target directory tree

```
neeve-copilot/
├── README.md, sync_skills.sh, setup-dev.sh, .git-hooks/, .github/workflows/
└── neeve/
    ├── README.md                     # this architecture, one page: 4 layers + harness + loop
    ├── foundation.md                 # Layer 04 — company identity/culture (NEW, extracted)
    ├── engineering-principles.md     # Layer 03 — merges org/PRINCIPLES.md's eng-specific content
    ├── references/                   # framework's own canonical deep docs (NOT the per-repo book)
    │   ├── quality-gates.md          # canonical (replaces 6 duplicate copies)
    │   ├── security.md               # canonical (absorbs neeve-security-partner)
    │   ├── pm-lens.md                # from neeve-pm-partner
    │   └── design-review.md          # from neeve-design-partner
    ├── templates/
    │   ├── ci/integration-verify.yml         # NEW — Pillar 2 item 3
    │   └── hooks/pre-commit-context-sync     # NEW — Pillar 2 item 4, installed into target repos
    ├── install.sh                    # moved from products/robin/
    ├── scripts/                      # moved + shared_refs_sync.sh, check_org_sync.py (rewritten)
    ├── dist/zips/                    # gitignored
    ├── agent-src/neeve/AGENT.md      # THE unified agent
    ├── skills-src/                   # to-prd/ to-erd/ to-spec/ implement-spec/ code-review/
    │   │                             #   repo-ask/ debug-trace/
    │   └── repo-intel/               # UPDATED: now produces the 3-file OKF book (see Layer 02)
    │                                 #   + installs the pre-commit hook into the target repo
    ├── context-src/
    │   └── base.md                   # house rules = foundation.md + engineering-principles.md digest
    ├── prompts-src/  hooks-src/
    │   ├── refresh-context.sh        # existing SessionStart hook
    │   └── pre-merge-checklist.sh    # NEW — Stop-hook, Pillar 2 item 5
    └── products/robin/
        ├── product-overview.md       # feeds foundation.md's Product section for Robin
        ├── repo-level OKF books       # committed in each repo, seeded by init-repo.sh
        └── skills-src/  neeve-dls/  ot-building-automation/
```

Note: each target product repo (robin-ai, robin-web, dls-neeve, ...) gets its
own `introduction.md` / `index.md` / `appendix.md` **at that repo's root**,
committed to that repo — not shown in the tree above since it lives outside
`neeve-copilot` entirely, in each of the 16 consuming repos.

Tier-4-equivalent (Custom & User Context) is documented in `foundation.md` or
`README.md`, never a directory.

**Deleted:** all 8 dirs in `products/robin/agents-src/` (+ README),
`org/.github/agents/neeve-ot-specialist.agent.md`, `org/` wrapper dirs after
moves, `products/robin/install.sh` (moved), stale `__pycache__/`. **Audit
before delete:** the legacy "Neeve Dev AI Framework" (32 prompt files/12
scripts/4 hooks) if it exists as a sibling directory — confirm nothing there
is un-migrated before removing.

## Dedup: single canonical source, generated copies downstream

Six `references/quality-gates.md` copies are already byte-identical
(md5-verified) plus restated in `base.md`. Skill zips must stay
self-contained and `skills_sync.sh check` diffs byte-for-byte, so: canonical
lives in `neeve/references/`, physical copies are **generated**, not
hand-duplicated.

- NEW `neeve/scripts/shared_refs_sync.sh`: `sync` / `check`; destinations
  declared in-script (6 quality-gates paths, `code-review/references/security.md`,
  pm-lens/design-review skill copies). Generated files get a
  `<!-- GENERATED from neeve/references/... -->` header.
- `skills_sync.sh pack` calls `sync` first; CI runs `check`.
- `base.md`'s `## Quality Gates` body → `{{QUALITY_GATES_FRAGMENT}}` rendered
  from `references/quality-gates.md`.

## Script / installer changes

- `install.sh`: two-root skill discovery (`neeve/skills-src`,
  `neeve/products/*/skills-src`); `AGENTS_SRC_DIR` → `neeve/agent-src`;
  **add prune step** removing the 8 retired agent filenames from every
  installed harness location so ghost agents stop auto-triggering.
- `skills_sync.sh`: two-root discovery, fail on name collision, calls
  `shared_refs_sync.sh sync` before pack.
- `context_render.py`: no longer renders a per-repo repo-book (that's now
  `repo-intel`'s job, checked into the target repo); it keeps rendering the
  thin house-rules pointer files (`AGENTS.md`/`CLAUDE.md`/`.cursorrules`)
  from `foundation.md` + `engineering-principles.md`, with a one-line import
  of that repo's own `introduction.md`/`index.md`/`appendix.md` where the
  tool supports `@import` (Claude Code), or an explicit pointer sentence
  otherwise.
- `repo-intel/SKILL.md`: rewritten to (a) produce `introduction.md`,
  `index.md`, `appendix.md` instead of a single `CONTEXT.md`, per the content
  contract in Layer 02 above, and (b) on first run in a repo, install
  `templates/hooks/pre-commit-context-sync` into that repo's `.githooks/` and
  set `core.hooksPath`.
- `agents_render.py`: `AGENTS_SRC` constant only.
- `prompts_sync.sh`, `hooks_sync.sh` (add `pre-merge-checklist.sh` to the
  sync list), root `sync_skills.sh`, `setup-dev.sh`, `.gitignore`: path updates.
- `test_*.py`: updated fixtures; new tests for `shared_refs_sync.sh check`
  and for `pre-commit-context-sync`'s deterministic checks (symbol diff,
  hash check, structural diff) against a small fixture repo.

## Docs / CI for this repo

- `check_org_sync.py` (→ `neeve/scripts/`): asserts the agent's routing table
  names every shipped skill exactly once (derived from both skills-src
  roots); asserts `security.md` headings; asserts `foundation.md`/
  `engineering-principles.md` citations in pm-lens/design-review.
- `ci.yml`: path updates; add `shared_refs_sync.sh check`; add a lint step
  that the 8-stage loop table in `AGENT.md` matches the deck's stage names
  (simple string-presence check, not full parsing); add a unit-test job for
  `pre-commit-context-sync` against the fixture repo.
- READMEs: `neeve/README.md` is the architecture summary (this plan's Pillars
  1–3, condensed) and explicitly documents that Layer 02's three files live
  in *target* repos, not here; `products/robin/README.md` slims to
  Robin-specific content.

## Migration order (one commit per phase, installer green throughout)

- **Phase 0 — baseline**: branch off `org-wide-agentic-coding`; record
  baseline of all `test_*.py`, `skills_sync.sh check`,
  `HOME=$(mktemp -d) bash .../install.sh --claude-code --copilot`.
- **Phase 1 — content consolidation** (no moves): extract `foundation.md`
  from `org/PRINCIPLES.md`'s non-engineering sections + product-portfolio
  framing; write `engineering-principles.md` from the rest; create
  `references/pm-lens.md`, `references/design-review.md`; merge
  security-partner/reviewer content into `references/security.md` and
  `code-review/references/principles.md`; convert `to-prd`/`to-erd` to
  skills; add explicit Design-phase + SOLID-mapping checklist lines to
  `to-spec`; write `agent-src/neeve/AGENT.md` with the 8-stage routing table;
  `git rm` the 8 agent dirs + OT placeholder; update `check_org_sync.py`,
  `base.md` tables, `ci.yml`, install summary text, cross-references.
- **Phase 2 — directory restructure**: `git mv` skills/agent/scripts/install
  into the tree above; move `PRINCIPLES.md` content into `foundation.md` +
  `engineering-principles.md`; rename `products/robin/agents-src` deletions
  finalized.
- **Phase 3 — Layer 02 mechanism**: rewrite `repo-intel/SKILL.md` to target
  the 3-file OKF book + hook install step; write
  `templates/hooks/pre-commit-context-sync` (symbol diff, hash check,
  structural diff) with a small fixture repo for its tests; write
  `templates/ci/integration-verify.yml`, `hooks-src/pre-merge-checklist.sh`,
  `shared_refs_sync.sh`, `{{QUALITY_GATES_FRAGMENT}}` wiring, CI check steps.
- **Phase 4 — docs**: `neeve/README.md` architecture summary (all 3 pillars +
  where Layer 02's files actually live), `products/robin/README.md` slim,
  `docs/Feature-Reference.md` update.
- **Phase 5 — pilot rollout** (first real use of Phase 3's mechanism): run
  `repo-intel` against one real target repo (pick a small one, e.g.
  `alc-hello-addon`) to generate its `introduction.md`/`index.md`/
  `appendix.md` and install the pre-commit hook there; validate the hook
  fires correctly on a real commit before recommending rollout to the other
  15 repos.

## Verification

1. `python3 neeve/scripts/test_context_render.py -v` (+ other test files, +
   new shared-refs tests).
2. `bash neeve/scripts/skills_sync.sh check` and `shared_refs_sync.sh check`.
3. Render smoke: `--house-rules` for the thin global pointer files.
4. Full install into throwaway `HOME`: assert 10 skills per tool, exactly one
   `neeve` agent per tool (old 8 absent), `pre-merge-checklist.sh` present
   alongside `refresh-context.sh` in the Claude hook config.
5. `python3 neeve/scripts/check_org_sync.py`.
6. Pilot repo check (Phase 5): confirm `introduction.md`/`index.md`/
   `appendix.md` exist at the pilot repo's root, `.githooks/pre-commit` is
   committed and `core.hooksPath` is set, and a deliberately-stale commit
   (add a function, don't touch `appendix.md`) is caught by the hook.

## Risks / open questions

1. **Design (stage 2) folded into `to-spec` rather than its own skill** —
   revisit if `to-spec` becomes too large; flagged, not silently decided away.
2. **Symbol extraction tooling per language** — `pre-commit-context-sync`
   needs a real chosen tool (ctags vs tree-sitter vs per-language scripts) for
  each stack across the product repos (Python, TypeScript, Go from the repos themselves).
   Pick one during Phase 3, validated against the Phase 5 pilot repo before
   generalizing — do not assume one tool covers every stack without checking.
3. **Hook enforcement is per-repo, not global** — a repo owner could remove
   `.githooks/pre-commit` or unset `core.hooksPath`; the required-CI-status
   check is the real backstop, so CI wiring (Phase 3) is not optional even
   though it looks like belt-and-suspenders with the local hook.
4. **`appendix.md` staleness under refactors** — a rename/move across many
   files may produce a large `TODO(purpose)` diff at once; acceptable
   (visible, not silent) but flag to the pilot-repo owner as expected
   behavior, not a bug.
5. **Integration Verification template is new scope** for this repo (a
   template, not a live workflow) — actual adoption in each of the 16 product
   repos, including wiring `pre-commit-context-sync`, is a separate rollout
   per repo after the Phase 5 pilot validates the mechanism.
6. **Legacy "Neeve Dev AI Framework"** — must be checked for un-migrated
   content before any deletion; location not yet confirmed in this repo.
7. Stale installs on engineer machines are handled by the install.sh prune
   step; without it, ghost agents keep auto-triggering.
8. `robin-skills-*` release tag naming is now a misnomer — deferred, not
   part of this restructure.

**Production consequence:** this changes what every engineer's AI tooling
loads globally, what every target repo's commit-time checks look like, and
what CI templates product repos are offered — no customer system is touched
directly. A too-strict `pre-commit-context-sync` (blocking instead of
warning) could slow down every commit in an adopting repo; start it in
warn-only mode during the Phase 5 pilot and only make it blocking after
validating false-positive rate. Blast radius: internal dev tooling +
per-repo commit workflow, not customer-facing systems. Rollback: `git revert`
in `neeve-copilot`; per-repo, `git config --unset core.hooksPath` removes the
hook immediately. **Gaps:** deep managed-settings/policy-tier enforcement
across all consuming repos remains future rollout work, not delivered by this
plan; Codex/Cursor/Antigravity renders remain best-effort, verified only by
smoke checks; symbol-extraction tool choice is deferred to Phase 3, not
pre-decided here.
