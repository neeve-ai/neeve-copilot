# Implementation Plan

**Version 3 — 2026-09-02.** Supersedes v2. The bespoke connector is out (D7); one surface
serves three populations (D9); cross-repo intel gets a git home with a freshness contract
(D8); workspaces self-provision (D10).

**Status:** Plan. No code changed.
**Companion docs:** `ARCHITECTURE.md` (what) · `redesign-proposal.md` (why) ·
`directory-redesign.md` (where) · `superseded/connector/**` (a service we decided not to build).
**Accuracy caveat:** file/line references come from research probes rather than a reading of
every file. Treat specific line numbers as "confirm on first read."

---

## 1. What changed from v2

| v2 said | v3 says | Because |
|---|---|---|
| Build a `neeve-context` MCP server first; Track B runs in parallel | **No connector at all.** Track B deleted | Every justification depended on a browser population (D7) |
| Layers 04/03a served over MCP on QUERY | **Read as files from a clone** (Pull) | All three populations have a filesystem and git |
| Two distribution channels with opposite properties | **One channel** — plugins | claude.ai out of scope |
| `Blocked` for PMs requires connector write tools | **Pre-commit + CI, uniformly** | Everyone commits to git |
| Discipline split was one of five moves | **The primary rationale.** Three populations, one ambient plane | A designer otherwise gets `mypy --strict` as a mandatory rule |
| Cross-repo grounding via `book_search` | `cross-repo/` in git + an aggregation job (D8) | A scheduled job is not a service (A-10) |
| Onboarding not addressed | **`init_workspace.sh` is a first-class deliverable** (D10) | Non-engineers on a developer surface is now risk #1 |

**Net effect: the redesign survives almost entirely; the service does not.** Five of the six
moves are untouched, ~1,700 lines of connector specification are retired, and the enforcement
story gets *stronger* because everything is deterministic git/CI.

Preserved unchanged from v1/v2: **D1** (frontmatter membership), **D2** (never rename the
`neeve` agent), **D3** (discipline plugins), **D4** (two planes).

---

## 2. Preconditions

| # | Open item | Blocks | Resolution |
|---|---|---|---|
| **O-1** | **Product workflow stages and gates** — who authors them | P3, P4 (product ambient block) | A named PM. Not a technical task |
| **O-2** | **Design workflow stages and gates** — who authors them | P3, P4, and the design discipline shipping at all | A named designer. Not a technical task |
| **O-3** | **Can a PM/designer complete Claude Code desktop setup?** | Everything — if not, adoption is zero | Watch one of each do it, unassisted, in P0.5 |
| **O-4** | Does the agent read the file when the routing block points at it? | Safe to ship P4 | Spike S-1 |
| **O-5** | PRD/design-doc substrate: Confluence or git planning repo? | P6, and the enforcement ceiling for those artifacts | Confluence tops out at `Surfaced`; git gives `Blocked` |
| **O-6** | Split `rca-retro-adr` into three? | P5 (it is a rename in disguise) | Judgement call |
| **O-7** | `dist/` committed, or marketplace `git-subdir` source? | P7 layout | Test one marketplace entry |

**O-1, O-2, and O-3 can invalidate rather than adjust.** Two of them are staffing decisions,
which is the honest characterisation of the biggest risk in this plan: the missing pieces are
content and adoption, not engineering.

Closed by D7: availability owner, write-path bypass, audit design, EMA auth, connector
observability, prompt-injection surface.

---

## 3. Two spikes, both cheap, both gating

### S-1 — the routing experiment (gates P4)

The redesign moves knowledge out of the always-on block on the bet that an agent will **go
read the file**. If it answers from priors instead, P4 deletes 400 lines and replaces them
with an instruction nobody follows.

**Method.** Take one currently-pushed fact — the 16-repo table. Put it in a file. Create a
test profile whose ambient block omits the table and carries only a routing pointer. Run ~20
tasks needing repo knowledge, with and without the pointer. Measure: does the agent open the
file, or answer from memory, and how often is the memory answer wrong?

Cheaper than the v2 version — no server to stand up, just a file and a pointer.

| Result | Action |
|---|---|
| Reads reliably | Proceed with P4 |
| Reads only with a strong pointer | Proceed; treat routing wording as load-bearing — version and test it |
| Doesn't read even with a good pointer | **Stop.** Re-scope P4 before doing it |

Effort: 1 day.

### S-2 — the onboarding walkthrough (gates the whole programme)

Sit with one PM and one designer. Have them install Claude Code desktop, clone a planning
repo, and complete one real task. Do not help. Record every point of friction.

This is risk #1 and it is untested. If setup takes an afternoon and two Slack messages to an
engineer, the framework has no non-engineering users regardless of how good the context is.

Effort: half a day. **Run it before P4**, so the ambient block can be written for the
audience that actually exists.

---

## 4. The plan at a glance

Single track now.

| Phase | Branch | Effort | Depends on | Gate |
|---|---|---|---|---|
| **P0** Land the docs | `docs/redesign-proposal` | 0.5d | — | Links resolve; reviewable |
| **P1** Safety & hygiene | `fix/*` (3 branches) | 1d | — | Existing CI + 2 new regression tests |
| **P2** Registry | `redesign/registry-and-sources` | 1–2d | — | Every repo present; SoR map covers every layer |
| **P3** Process as data | `redesign/process-executable-rules` | 4–6d | O-1, O-2 for non-eng stages | `tiers.yaml` computes a real ratio; gates reproduce today's behaviour |
| **P4** Ambient shrink | `redesign/ambient-shrink` | 3–5d | P2, **S-1**, **S-2** | Core ≤45 lines; any one person ≤100; each discipline free of the others' tokens |
| **P5** Flatten · move · rename | `redesign/flatten-and-disciplines` | 3–4d | P1, P4 | Full CI green; throwaway-`$HOME` smoke; no orphaned skills after re-sync |
| **P6** Foundation & cross-repo | `redesign/foundation-and-cross-repo` | 3–4d | P5 | No placeholder leaks; A-9 check in CI; freshness check flags a stale entry |
| **P7** Surfaces & distribution | `redesign/surfaces-and-dist` | 2–3d | P5, P6, O-7 | Plugin drift check; workspace provisioning verified on a clean machine |
| **P8** Evals & the loop | `redesign/evals` | 3d+ | P7 | ≥1 eval case per discipline's core skills |

Umbrella tracking name: **`redesign/context-architecture`** (epic, not a branch).

Rough total: **4–6 weeks of focused effort**, down from 6–8 in v2 — P7 shrank by more than
half and Track B is gone. The least compressible item remains P4's editorial work.

---

## 5. Phase detail

### P0 — Land the design docs ✅ **done**

Moved out of scratch into `docs/redesign/`, with the withdrawn connector design under
`docs/redesign/superseded/connector/`. Inter-document links rewritten to relative paths so
later PRs can cite them stably.

**Gate:** met — every cross-reference resolves.

---

### P0.5 — Run S-1 and S-2

Not a code phase. Both spikes, both cheap, both gate real decisions. Do them before P4 is
scoped, not after it is built.

---

### P1 — Safety & hygiene

Independent of the redesign, but P4/P5 edit the same files. Three small branches.

| # | Change | File |
|---|---|---|
| 1.1 | **Data-loss fix.** `_strip_legacy_unmarked_block` deletes from the legacy header to end-of-region, destroying user content below it — including when a user writes that heading themselves. Require the exact string **and** stop at the next top-level `#`; write a `.bak` first | `merge_house_rules.py:53-64` |
| 1.2 | Add `--remove` so the SessionStart hook can be uninstalled. No removal path exists | `merge_session_hook.py` |
| 1.3 | **Stop scope escalation.** `refresh-context.sh` → `sync_skills.sh` → `install.sh --all` reinstalls into all five tools regardless of choice. Persist the selection to a receipt and replay only those; drop the duplicate `git pull`; surface failures | `refresh-context.sh:51`, `sync_skills.sh:14` |
| 1.4 | Add `test_merge_default_agent.py` to the test list — 133 lines that never run | `ci.yml:40-84` |
| 1.5 | Add `--upgrade-from <old-value>` for forward migration | `merge_default_agent.py` |
| 1.6 | Correct the stale "§7 skills manifest" advice — there is no §7 | `CONTRIBUTING.md:174-179` |

**Gate:** existing CI plus two new `merge_house_rules` regression tests.

---

### P2 — Registry

`registry/repos.yaml` — extracted from the 16-repo table inside
`products/robin/context/product-overview.md`:

```yaml
repos:
  - id: robin-ai
    purpose: <one line>
    owner: <team>
    products: [robin]
    book: .help/
```

`registry/sources.yaml` — the source-of-record map, and the input that generates
`ambient/routing.md`:

```yaml
domains:
  - domain: foundation          # Layer 04
    sor: git:neeve-copilot/foundation/
    delivery: pull
  - domain: process-narrative   # Layer 03a
    sor: git:neeve-copilot/process/narrative/
    delivery: pull
  - domain: process-rules       # Layer 03b
    sor: git:neeve-copilot/process/gates/
    delivery: executable        # never network-served — A-3
  - domain: cross-repo-intel    # Layer 02½
    sor: git:neeve-copilot/cross-repo/
    delivery: pull
  - domain: repo-context        # Layer 02
    sor: git:<product-repo>/.help/
    delivery: pull
  - domain: live-work-state
    sor: jira
    delivery: query
    connector: atlassian
    cache: never
```

**Gate:** every repo from the old table present; an entry per layer in `ARCHITECTURE.md` §3;
a validator rejects any domain with two `sor` values — invariant A-1 enforced mechanically
rather than by review.

---

### P3 — Process as data

**The centre of gravity.** The only enforcement mechanism in the redesigned system, and now
pure git/CI.

| File | From | Content |
|---|---|---|
| `process/workflow.yaml` | Design Loop prose duplicated across `neeve/README.md`, `AGENT.md`, `HOW-TO-USE.md`, root `README.md`, 11 skill bodies | stages · owner · input · output · acceptance contract — **for all three disciplines** |
| `process/gates/quality-gates.yaml` | `references/quality-gates.md` (133 lines of prose) | The seven gates **as commands**, per stack |
| `process/gates/artifact-rules.yaml` | `pm-lens.md` items 1–3, `design-review.md` | Predicates a linter can run against a PRD, ERD, or design doc |
| `process/tiers.yaml` | New | Every rule → `Blocked` \| `Surfaced` \| `Advised`, per substrate |
| `process/narrative/` | Narrative half of `engineering-principles.md` | Layer 03a, beside the rules it explains |

Plus **code-gen**: `process/gates/*` → the per-workspace pre-commit hook and CI check, so a
gate is defined once and executed everywhere.

**Blocked on O-1 and O-2 for the non-engineering stages.** The engineering loop can be
encoded from existing content today; product and design stages cannot be invented. Encode
engineering first, leave the other two as declared-but-empty stage sets rather than guessing.

**Constraints.** Predicates are mechanical — field presence, shape, enumerations, referential
checks against `registry/repos.yaml`. No model calls (A-2). This catches **omission, not
vagueness**: "improve things" passes as an outcome. Accept it.

**Gate:** `tiers.yaml` yields a real ratio in CI; generated hook and CI check reproduce
today's gate behaviour on a sample repo with zero behavioural diff.

---

### P4 — Ambient shrink

**Depends on S-1 and S-2.** This is now the phase that most directly delivers the redesign's
purpose: three populations sharing one plane, each seeing only their own context.

- `ambient/core.md` — ~40 lines: identity, stakes, precedence, routing pointers.
- `ambient/routing.md` — **generated** from `registry/sources.yaml`.
- `disciplines/{core,engineering,product,design}/discipline.yaml`, glob-discovered.
- `disciplines/*/ambient.md` — engineering can be written from existing content; **product and
  design need O-1/O-2 authors.** Ship a discipline with no ambient block rather than an
  invented one.
- `context_render.py` → `tools/render_ambient.py`: drop the `products/robin` hardcode (`:19`),
  add `--disciplines` and `--products`, delete dead `OUTPUT_FILES` (`:29`) and the four dead
  fragment renderers (`:32-53`).
- Rewrite `test_context_render.py`'s brand-pinned assertions (`:25,26,60`).

**Budgets:** `core.md` ≤45 lines; any single person's total ≤100.

**Least compressible phase in the plan.** Deciding which of the 469 lines are role-neutral is
editorial judgement. Read the *rendered* output, not the source diff.

**Gate:** a designer's payload contains none of `mypy` / `cov-fail-under` / `ORM` / `kubectl`;
a PM's likewise; every discipline within budget; no `{{PLACEHOLDER}}` leaks.

---

### P5 — Flatten, move, rename

**The big disruptive commit.** One commit — the path churn overlaps completely.

**Structural:** delete the `neeve/` wrapper; `neeve/skills/*` → `skills/*`; the Robin skill
moves up with `products: [robin]`; add `disciplines:` frontmatter to all 11 skills; move the
`security.md` canonical out of the `code-review` skill; rewrite `shared_refs_sync.sh` so
destinations are **derived** from frontmatter × `discipline.yaml` (today: one canonical, six
hardcoded paths, four skills silently missing).

**Renames:**

| Old | New | Why |
|---|---|---|
| `to-erd` | `to-workitems` | ERD reads as Entity Relationship Diagram; the description spends a clause disclaiming it |
| `neeve-dls` | `design-system` | Org name in a skill name; stutters when namespaced |
| `code-review` | `production-review` | Collides with Claude Code's built-in `/code-review` |

**Deletions:** `neeve/prompts/` + `prompts_sync.sh` (9 files, 89 lines, installed nowhere);
two dead context fragments.

**Mechanical breakage, all fixed here:** ~400 markdown citations · `ci.yml`'s 18 path refs ·
`release.yml`'s 29 occurrences including a `robin-skills-v*` tag trigger that means **no
release fires under any other name** · `.git-hooks/post-commit`'s `SKILLS_PATH` regex ·
`.gitignore` · 27 brand strings in three test files · `AGENT.md`'s routing table ·
**the `.neeve-manifest` rename migration**, which is the only item that fails *silently* on
other people's machines.

**Gate:** full CI green; `export HOME=$(mktemp -d) && bash install.sh --all` clean; and sync a
`$HOME` holding the *old* skill names to confirm no orphans remain.

---

### P6 — Foundation & cross-repo intel

Two related pieces of content work.

**Foundation restructure** — a move, not an extraction:

| From | To |
|---|---|
| `foundation.md` | `foundation/{identity,personas,customers}.md` |
| `products/robin/context/product-overview.md` — narrative | `foundation/products/robin.md` |
| — repo table | already `registry/repos.yaml` (P2) |
| — local-dev/K8s runbook | Robin's own `.help/` book; it is repo context |
| `engineering-principles.md` §§ PRD & Scoping (L18-46) | `disciplines/product/references/` |
| — §§ Design (L50-71) | `disciplines/design/references/` |
| `products/robin/context/fragments/dls-usage-notes.md` | `disciplines/design/references/` |
| `products/robin/context/fragments/ot-domain-notes.md` | `skills/ot-building-automation/references/` |
| `products/robin/README.md` | `docs/setup.md` — the framework's real setup doc, misfiled under a product |

Then delete `foundation.md`, `engineering-principles.md`, and `products/` entirely.

**Cross-repo intel (D8)** — new Layer 02½ home:

```markdown
# Cross-repo: auth flow, robin-ai → robin-web → one-portal

verified-against:
  robin-ai:   a1b2c3d
  robin-web:  e4f5g6h
  one-portal: i7j8k9l
```

- `cross-repo/` directory with the `verified-against:` convention.
- A **freshness check** reusing `pre-commit-context-sync`'s manifest-hash pattern, pointed at
  `cross-repo/`: flag entries whose referenced repos have moved past the recorded SHA.
- A **book aggregation job** — scheduled, pulls the ~16 `.help/` sets into a local searchable
  directory. A cron job, not a service (A-10).
- **An authoring path**, without which the store stays empty: a cross-repo mode for
  `repo-intel` — *"trace this contract across every repo that touches it, and write the
  finding to `cross-repo/` with the SHAs you verified against."*

**Gate:** no placeholder leaks; citation checks pass; `docs/setup.md` reachable from the root
README; **the A-9 check is in CI** (ambient output contains nothing sourced from
`foundation/`); the freshness check flags a deliberately-stale cross-repo entry.

---

### P7 — Surfaces & distribution

Much smaller than v2 — one distribution channel.

- `surfaces/claude-code/` — plugin build → `dist/plugins/<discipline>/`; root
  `.claude-plugin/marketplace.json`; the SessionStart hook; marker-merge and `settings.json`
  surgery.
- `surfaces/adapters/` — thin per-tool copiers for Codex, Cursor, Copilot, Antigravity.
  Skills receive **zero** per-tool transformation, so each is a destination path.
- Keep `agents_render.py` — those four tools still need TOML transcoding, per-tool frontmatter,
  skill-fallback synthesis, and tool-vocabulary translation. No plugin format does this.
- **`tools/init_workspace.sh` — promoted to a first-class deliverable (D10).** Three workspace
  kinds: code repo, planning repo, design repo. Each scaffolds its book/templates, its
  pre-commit hook, and a committed `.claude/settings.json` carrying
  `extraKnownMarketplaces` + `enabledPlugins` so the right discipline plugin auto-registers
  and enables **on folder trust**. This is what makes a developer surface tractable for
  non-developers: install the app, clone one repo, trust it.

**Gone from v2:** org-library ZIPs, `PUBLISHED.yaml` checksum manifest, the manual-publish
drift problem, 200-character description rewrites, `PORTABILITY.md`.

**Gate:** plugin drift check green; throwaway-`$HOME` smoke test; and the real one —
**a clean machine, a fresh clone, and a non-engineer reaching a working first task without
help** (re-run of S-2).

---

### P8 — Evals & the feedback loop

- `evals/<skill>/cases/` — start with each discipline's two or three core skills.
- **Lessons aggregation**: a scheduled job collecting `.help/lessons.md` across clones,
  attributing each correction to the artifact that caused it — skill, gate, book, or
  cross-repo entry.
- `claude plugin eval` is early-access gated and printed a not-enabled message in this
  environment. **Design for it, don't depend on it**; a plain harness over `claude -p` is the
  fallback.

**Gate:** ≥1 eval case per discipline's core skills; the corrections path demonstrably closes
on one real example.

---

## 6. Verification gates by stage

| Check | Today | Change |
|---|---|---|
| `shared_refs_sync.sh check` | 1 canonical → 6 hardcoded paths | P5: derived from frontmatter |
| `skills_sync.sh check` | zip round-trip diff | P7: kept for adapters only |
| `test_context_render.py` | brand-pinned assertions | P4: parameterized + budgets + negative assertions |
| `test_merge_house_rules.py` | — | P1: two data-loss regression tests |
| `test_merge_default_agent.py` | **never runs** | P1: added to CI |
| `check_org_sync.py` | presence-only; docstring claims "exactly once"; no reverse check | P5: reverse check, discipline validity, `discipline.yaml` well-formedness |
| — | — | P2: A-1 check — no domain with two SoRs |
| — | — | P3: tiers ratio computed and reported |
| — | — | P6: A-9 check; cross-repo freshness check |
| — | — | P7: `dist/` drift check; workspace provisioning smoke test |

Local pre-PR sequence stays as `CONTRIBUTING.md` §5 describes, plus the throwaway-`$HOME`
install smoke test, which CI still does not run for you.

---

## 7. Explicitly out of scope

- **Any bespoke service or MCP server** (A-10, D7). Trigger condition for revisiting is in
  `ARCHITECTURE.md` §15.
- **claude.ai / browser-only support.**
- **The rebrand.** No rename of the framework, marker label, `neeve` agent, or
  `neeve.contextsync.*` keys. Prerequisite if ever taken up: a `KNOWN_LEGACY_LABELS` migration
  path plus P1's `--upgrade-from`.
- Federated cross-source search as a single tool.
- MCP-to-MCP federation.

---

## 8. Risks carried through the plan

1. **Onboarding cost for non-engineers.** Claude Code desktop assumes a dev environment. If a
   PM or designer can't get through setup, adoption is zero — worse than any context gap.
   Gated by S-2; mitigated by D10 workspace provisioning.
2. **Product and design workflow content does not exist** (O-1, O-2). Blocks two live
   populations. Needs named authors, not a plan. **The largest non-engineering dependency.**
3. **Discoverability** (O-4). Will the agent read the file? More reliable than a tool call,
   but the routing wording is load-bearing. Gated by S-1.
4. **P4 is editorial.** Cannot be accelerated by tooling.
5. **`cross-repo/` has no authoring path until P6's `repo-intel` mode ships.** A store nobody
   writes to stays empty.
6. **P5's silent failure.** The `.neeve-manifest` rename migration is the only breakage that
   fails quietly on someone else's machine.
7. **Corpus quality caps outcomes.** Books are uneven; TS/Go symbol detection is conservative.
8. **Confluence-hosted artifacts cannot be gated.** Accept `Surfaced` or move them to git
   (O-5).
