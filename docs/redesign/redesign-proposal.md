# Redesign Proposal: From Instruction Distribution to Enforced Context

**Status:** Proposal for discussion. No code changed.
**Revision history.** *2026-08-28:* source-of-record model introduced; Layers 03/04 placed in
NotebookLM, then reversed into git (invariant A-9 added). *2026-09-02:* **claude.ai declared
out of scope, and the bespoke connector dropped entirely (D7).** With every population
holding a git clone, the QUERY channel collapses into a file read; enforcement becomes
uniform pre-commit/CI; and the discipline split becomes the *primary* rationale rather than
one of five moves. Sections §6.1–§6.4, §7, and §8 are rewritten accordingly.
**Current system-level view: `ARCHITECTURE.md`.** Design detail for the service we
decided not to build is preserved in `superseded/connector/**`.
**Companion doc:** `implementation-plan.md` (v3) — the sequenced plan. This document is a
step back from it: what the system *should be*, not how to get there. See §9 for the mapping.

**Accuracy caveat:** the measurements in §2 come from research probes over this repo
rather than a line-by-line reading of every file. They were precise and internally
consistent, but treat specific line numbers as "confirm on first read."

---

## 1. Purpose, stripped of implementation

> Make AI agents behave like a competent Neeve colleague rather than a generic
> assistant — by giving them the org's context, the team's process, and the repo's map,
> consistently across whichever tool each person uses, and keeping all of that from
> rotting.

Four sub-goals: **grounding**, **process**, **portability**, **freshness**.

Everything in this proposal is judged against those four and nothing else.

---

## 2. Evidence base

Measurements taken from the repo as it stands, so this proposal can be argued with:

| Observation | Figure |
|---|---|
| Always-on payload injected into every request, every repo, every user | **469 lines / 3,930 words** |
| …declared precedence-winning (`context_render.py:68-74`) | *"mandatory and takes precedence… this block wins"* |
| …strictly engineering-only (unusable by PM/design) | ~30% |
| …single-product infrastructure detail (16-repo table + K8s runbook) | ~18% |
| …genuinely role-neutral | ~35% |
| Projection/distribution machinery | ~1,490 lines (of ~3.3k total) |
| Tools targeted | 5 |
| Per-tool transformation applied to skills | **zero** — one file, zipped once, unzipped byte-identically into 5 paths |
| Agents in existence, served by 309 lines of transcoding | **1** |
| Artifact type validated by CI and installed nowhere (`neeve/prompts/`) | 9 files + 89 lines |
| Deterministic enforcement reaching a product repo | 1 pre-commit hook, **warn-only** by default |
| CI assertions about product outcomes | **0** — all 9 are framework self-consistency |
| Skills with a role/discipline field in frontmatter | **0 of 11** (only `name` + `description`) |

Two corroborating details worth noting because they show the design already knows things
it hasn't acted on:

- The `quality-gates.md` fan-out reaches 6 of 11 skills. The 5 it skips — `to-prd`,
  `to-erd`, `rca-retro-adr`, `debug-trace`, `ot-building-automation` — are almost exactly
  the PM-adjacent/template-driven set. **The discipline line is already drawn in code and
  simply unnamed.**
- `to-erd:42-45` already refuses to hardcode a write path (*"ask where this org keeps
  planning docs"*) while `to-prd:137` hardcodes one. The better pattern exists in-repo and
  hasn't propagated.

---

## 3. What to keep

These are earned and should survive any redesign:

1. **Open Knowledge Format** — tool-agnostic markdown as source, projected per tool. It is
   the reason this is portable at all.
2. **One fact, one place** — with generated copies CI-diffed against canonicals, so
   editing a copy fails the build by design.
3. **"Scripts detect drift, models fix it"** — deterministic hooks surface mechanical facts
   (a hash changed, a symbol is undocumented) and never make a model call; judgment is
   handed to an agent-invoked skill. This is a genuinely sophisticated instinct.
4. **Layer 02 committed to the product repo, layers 03/04 never** — the right split.
5. **One router, not one agent per skill** — the recorded lesson from collapsing eight
   agents into one.
6. **Making staleness loud** — a warning, a red check, a TODO marker, rather than silent
   rot.

---

## 4. The central flaw

**This is an instruction-distribution system wearing an enforcement system's clothes.**

The repo's own Pillar 2 states: *"Instructions alone are not enforcement — deterministic
checks are."* The actual allocation of effort:

- ~1,490 lines distributing prose
- a 469-line always-on manifesto
- ~4,000 lines of skill prose
- **versus** one warn-only pre-commit hook, and a CI gate that checks whether the router
  mentions every skill

The seven quality gates — the real enforcement — exist as 133 lines of markdown
*describing* `mypy --strict`, `ruff check`, and `pytest --cov-fail-under=95`, which a model
is asked to please run. `quality-gates.md:3` says *"Every task that produces or modifies
code must pass all applicable gates,"* and nothing in the system can tell whether that
ever happened.

So the framework states the correct principle and then spends the overwhelming majority of
its energy on the mechanism it just called insufficient. Every move below follows from
fixing that.

---

## 5. Five moves

### Move 1 — Tier every rule by enforcement strength; make the weakest tier the exception

| Tier | Mechanism | Form |
|---|---|---|
| **Blocked** | A deterministic check prevents the bad state — CI job, required PR status, blocking hook | Executable |
| **Surfaced** | The gap is made loud at the moment of work — warning, TODO marker, red check | Executable |
| **Advised** | Prose the model reads and may follow | Markdown |

Today essentially everything is **Advised**.

Concretely:
- `quality-gates.md` should not be a document *describing* commands. It should **be** the
  commands — a runnable check invoked by a `Stop`/`PostToolUse` hook or a CI job — with
  prose reduced to why-it-matters and how-to-interpret-a-failure.
- "PRD as system of record" sticks only if merging without a linked PRD fails a check.
  As a house rule it is a wish.
- Every rule in the system gets tagged with its tier, and an untiered rule is a review
  finding.

**Caveat that must be respected:** the repo's own rule that deterministic hooks never make
model calls still holds. A gate may only assert mechanical facts. "Is this a contract
change?" stays a judgment call routed to a skill; "did `mypy --strict` exit non-zero"
does not.

### Move 2 — Treat ambient context as a scarce budget, not a manifesto

**Target: ~40 lines.** Down from 469.

The ambient block should carry only what is irreducible: who we are, what's at stake, the
precedence rule, and *pointers* to where everything else lives. Everything else becomes
retrieval-on-demand — which is precisely what skills are, a better mechanism this
framework already ships and under-uses.

Rationale: 469 lines of precedence-winning prose is injected on every turn, in every repo,
where ~55% is irrelevant to any given task, it costs tokens continuously, and it has never
been shown to change a single outcome.

**Shrink before scoping.** An earlier plan split the payload three ways by discipline;
splitting a bloated artifact into three bloated artifacts treats the symptom. And with one
surface shared by three populations (§7.2), the per-discipline split is no longer optional
polish — it is the only thing stopping a designer receiving `mypy --strict` as a mandatory
rule.

Success metric: *how small is the ambient block?* — not how comprehensive.

### Move 3 — Invert the investment: workspace grounding is the crown jewel

Layers 03/04 (company prose, engineering principles) are largely things a strong model
already knows or can infer, plus a small genuinely proprietary core (customers, personas,
product topology). Layer 02 — the `.help/` book — is **100% proprietary and 100%
unavailable to the model otherwise.** It is the thing that actually makes an agent good in
your code.

It is also the layer the framework invests the least code in, while spending most of its
machinery distributing the commodity layers. **The value is inverted relative to the
effort.**

Proposed:
- Make the book the centerpiece: better structure, and real verification that its claims
  still match the code (beyond the current manifest-hash and symbol diff).
- Generalize "repo" to **workspace**, so a PM's unit of work — a Jira project, a product
  area, a customer segment — receives the same grounding treatment. The Atlassian MCP
  already available makes a `domain-intel` analogue of `repo-intel` cheap.
- The pre-commit hook's symbol detection is *"exact for Python but conservative for
  TypeScript/Go"* (per `HOW-TO-USE.md`). Closing that gap is higher-value than any
  additional prose anywhere in the system.

### Move 4 — Unbundle the three products that are currently fused

This is the structural reason adding a discipline touches everything. The repo is three
products with different owners and different change rates, sharing one CI gate:

| Product | Owner | Change rate | Bar to change |
|---|---|---|---|
| **Mechanism** — how context reaches agents (install, render, merge, hooks) | Platform/tooling | Rarely | High |
| **Process** — the Design Loop, stage contracts, gates | Eng + PM leadership | Quarterly | Deliberate, cross-functional |
| **Skills** — task playbooks | Practitioners | Weekly | Low; contribute freely |

Today a skill tweak and an installer change pass through the same eight-check gate, which
simultaneously over-guards skills and under-guards the mechanism.

Splitting them also makes **process a first-class artifact** rather than prose duplicated
across `neeve/README.md`, the router's routing table, `HOW-TO-USE.md`, the root `README.md`,
and eleven skill bodies — duplication that is why the process can drift from itself.

Per §6.1 rows 03a/03b, "process" resolves into two artifacts with one authoritative home
each, split by *purpose* rather than by audience:

| Form | Home | Read by |
|---|---|---|
| **Narrative** — why the loop is shaped this way, what a good PRD reads like | git `process/narrative/` | humans and agents, read from the clone |
| **Executable rules** — gate commands, validation predicates, contracts-as-data | git `process/gates/` | CI, pre-commit, connector validators |

The risk of one concept in two homes is the two descriptions disagreeing. **ADR-11 largely
dissolves it:** both now live in the same directory of the same repo, so they are reviewable
in one diff by one reviewer. Residual disagreement still surfaces as a failed gate rather
than silent divergence, since the executable half is the half that bites.

### Move 5 — Add the feedback loop, which is entirely missing

Nothing in this system measures whether any of it works. All nine CI assertions are
self-consistency: does the router mention every skill, do generated copies match, do zips
round-trip. There is zero evidence about whether `to-spec` produces better specs, whether
the house rules change behavior, or whether a book is accurate.

- **`lessons.md`** — the per-repo corrections log — is the seed of the right mechanism, but
  nothing aggregates it. A correction to a skill's output in one repo is a signal about
  *the skill*, not just that repo. Close that loop: aggregate corrections back to the
  artifact that caused them.
- **Eval cases per skill.** `claude plugin eval` is built for exactly this — fresh isolated
  session per case, optional no-plugin baseline arm, threshold-based exit code suitable for
  CI. It is currently **early-access gated** and printed a not-enabled message in this
  environment, so it cannot be load-bearing yet; design for it, don't depend on it.

Without this move, standardization is faith-based: you can enforce perfect consistency
without ever learning whether the thing you made consistent is any good.

---

## 6. Proposed shape

### 6.1 The layering: scope × delivery mode

The current model treats context as a **pyramid of scope** (org → principles → repo →
user), with everything pushed into the context window. That's one axis. The missing axis is
**delivery mode** — *when* a piece of knowledge reaches the model, and what it costs.

Each row also names its **system of record** — exactly one per layer, because a fact with
two authoritative homes is a conflict, not redundancy.

```
                     │ PUSH               │ PULL                │ QUERY
                     │ every turn, in ctx │ when the agent reads│ live, on demand
 SCOPE / SoR         │ file (AGENTS.md)   │ FILE IN A CLONE     │ existing connector
─────────────────────┼────────────────────┼─────────────────────┼─────────────────────
 04  ORG FOUNDATION  │ identity, stakes,  │ foundation, personas│ —
     static · prose  │ precedence,        │ customers, product  │
 SoR: git            │ ROUTING POINTERS   │ narrative           │
     foundation/     │ ~40 lines ◄── cap  │ → read from clone   │
─────────────────────┼────────────────────┼─────────────────────┼─────────────────────
 03a PROCESS         │ loop stage names   │ why it is shaped    │ —
     narrative       │ only (~5 lines)    │ this way; what good │
 SoR: git            │                    │ looks like          │
     process/narr./  │                    │ → read from clone   │
─────────────────────┼────────────────────┼─────────────────────┼─────────────────────
 03b PROCESS         │ —                  │ gate commands,      │ —
     executable      │                    │ validation preds,   │  (never a query —
 SoR: git            │                    │ contracts-as-data   │   A-3, see below)
     process/gates/  │                    │ → CI + HOOKS        │
─────────────────────┼────────────────────┼─────────────────────┼─────────────────────
 02½ CROSS-REPO      │ —                  │ contracts + flows   │ —
     intel           │                    │ spanning repos,     │
 SoR: git            │                    │ SHA-pinned          │
     cross-repo/     │                    │ → read from clone   │
─────────────────────┼────────────────────┼─────────────────────┼─────────────────────
 02  WORKSPACE       │ pointer to the     │ .help/ book         │ live tickets,
     repo / planning │ book (~2 lines)    │ skills = playbooks  │ deploy state
     / design space  │                    │ → read from clone   │ → ATLASSIAN · AWS
 SoR: git · Conf.    │                    │                     │   (never cached)
─────────────────────┼────────────────────┼─────────────────────┼─────────────────────
 01  TASK FRAME      │ the request itself │ —                   │ —
     repo · goal ·   │ assembled at       │                     │
     question        │ runtime            │                     │
 SoR: nowhere        │ NOTHING STORED     │                     │
─────────────────────┴────────────────────┴─────────────────────┴─────────────────────
                       ▲                    ▲                     ▲
                       │                    │                     │
                    costs tokens         costs tokens          costs nothing
                    EVERY turn           only when read        until asked
                    → keep it tiny       → THE DEFAULT HOME    → live state only
```

**What changed on 2026-09-02:** the QUERY column emptied out. Every row that pointed at a
bespoke MCP server now points at **a file in a local clone**, because all three populations
have a filesystem and git. QUERY retains only what genuinely cannot be a file — state that
changes faster than any sync — served by connectors that already exist.

That is strictly better on five axes: no network, no auth, no staleness window, works
offline, and nothing to operate.

**The governing rule:** *the larger and more volatile a body of knowledge, the further
right it belongs.* PUSH is a budget, not a home. Mass should migrate rightward over time.

**The one counter-rule, and it is load-bearing:** anything a *deterministic gate* must read
cannot live in the QUERY column. Row 03b exists for exactly this reason. A validator that
fetches its rulebook from an interactively-authenticated cloud service is not a validator,
and CI has no human present to authenticate. So process splits: the narrative that explains
it is queried, the rules that enforce it are pulled from git.

**The rule this table is most likely to be misread against:** rows 04 and 03a have
`SoR: git` **and** live in the QUERY column. That is deliberate. **Storage location and
delivery channel are independent decisions** (invariant A-9). Content sitting in the repo is
not a licence to render it into the ambient block — doing so reinvents the 469-line payload
with extra steps, and it is the most natural way for this design to decay.

**Two things changed from the original 4-layer model.** Layer 03 split in two (03a/03b
above). And Layer 01 is no longer *stored developer config in dotfiles* — it is the **live
task frame**, assembled per request from the current repo, goal, and question. That
reframing means Layer 01 needs no storage design at all, which is why it never belonged in
an install path.

**Where the system sits today:** effectively everything is in the PUSH column (469 lines)
or PULL (skills). The redesign's work is to move the bulk of PUSH into PULL — from *shipped
to everyone on every turn* to *read from a clone when relevant*.

### 6.2 Where MCP fits — a much smaller role than first assumed

An earlier version of this section argued MCP was load-bearing: with a browser population
that has no filesystem, it was the *only* channel to internal knowledge, and the only place
enforcement could live. **Both premises are gone** (§7, §8).

What MCP is left holding is genuinely narrow, and it is served entirely by connectors that
already exist:

| Category | Why it must be a query | Server |
|---|---|---|
| Live work state — tickets, sprint status, assignment | Changes faster than any sync interval; a committed copy is wrong on arrival | Atlassian |
| Deploy / cluster state | Same | AWS |
| Human-collaboration artifacts hosted outside git — Confluence pages | They live where non-framework stakeholders read them | Atlassian |

Everything else that was going to be a query is now **a file read from a local clone**. That
is better on five axes at once: no network, no auth, no staleness window, works offline, and
nothing to operate.

**The rule this settles**, as invariant A-10: *prefer a file in a clone, then an existing
connector, then nothing.* A bespoke server is the last resort, not the natural home for
knowledge.

**Two limits worth keeping on record**, because they shaped decisions elsewhere:

1. **MCP cannot push.** Resources are pull-only, so the irreducible ambient block stays a
   file regardless. This is architectural, not a gap to close.
2. **A `Blocked` gate can never depend on an MCP query.** Interactively-authenticated servers
   are absent in headless CI runs (A-3). That is why Layer 03b lives in git, and why a
   Confluence-hosted PRD tops out at `Surfaced`.
### 6.3 Mechanism: write to the standards, stop compiling to five backends

The projection layer exists to distribute **one** agent and **eleven** skills that receive
**zero** per-tool transformation — a compiler with five backends that all want the same
bytes. Meanwhile the industry is converging on the skill-folder + `SKILL.md` format and on
`AGENTS.md` for ambient context.

Proposed:
- Make the **source layout be the distributable layout** (plugin/skill-shaped), so there is
  no build step to keep in sync.
- Keep one thin adapter for tools that lag. `agents_render.py`'s TOML transcoding and
  tool-vocabulary translation is the only genuine translation in the repo and survives.
- Retire the rest of the fan-out as tools converge.

The whole mechanism on one page. **Only two rows have a projection step at all** — the rest
is content read straight from a clone, which is what dropping the connector bought:

```
  SOURCE OF TRUTH (this repo)      PROJECTION               REACHES THE AGENT AS
  ───────────────────────────      ──────────               ────────────────────

  ambient/  (~40 lines)  ────────> marker-merge   ────────> ~/.claude/CLAUDE.md
    identity · stakes ·              (idempotent,             ~/.codex/AGENTS.md
    precedence · POINTERS             BEGIN/END)              → in context EVERY turn
    ▲
    └─ routing.md GENERATED from registry/sources.yaml — cannot drift

  skills/                ────────> plugin build   ────────> marketplace entry
    task playbooks,                  + manifest              enabledPlugins, per discipline
    tagged by discipline                                     → loaded on relevance

  process/gates/         ────────> code-gen  ─────┬───────> pre-commit hook  [SURFACED]
    gate commands ·                  (no model               └─> CI required check [BLOCKED]
    validation predicates ·           call, ever)            Layer 03b — MUST stay in git
    contracts-as-data                                        (A-3: CI has no human to auth)

  ─ ─ ─  everything below is READ AS A FILE — no projection, no install, no service  ─ ─ ─

  foundation/            ────────>  (none)       ────────> agent reads from the clone
    Layer 04: identity ·                                   → NOT rendered into ambient
    personas · customers ·                                    (invariant A-9)
    product narrative                                      → citation resolves to a commit

  process/narrative/     ────────>  (none)       ────────> agent reads from the clone
    Layer 03a: why the loop                                → sits beside the gates it
    is shaped this way                                        explains: one diff, one review

  cross-repo/            ────────>  (none)       ────────> agent reads from the clone
    Layer 02½: contracts and                               → verified-against: SHAs
    flows spanning repos                                   → scheduled check flags drift

  registry/              ────────>  (none)       ────────> agent reads from the clone
    repos.yaml · sources.yaml                              → also GENERATES ambient/routing.md

  PRODUCT REPO  (committed there, never here)
  .help/ book            ────────>  (none)       ────────> every population reads directly
    introduction · index ·           freshness hook        [SURFACED on drift]
    appendix · memory · lessons      + aggregation job ──> local searchable book set
                                     (cron, not a service) lessons → feeds Move 5

  EXTERNAL SYSTEMS  (adopted, never built)
  Jira · Confluence · AWS ───────> existing MCP  ────────> tool call — LIVE STATE ONLY
```

Note what *stayed* and what changed shape. Layers 04 and 03a are still authored here, but
they are no longer **rendered** here and no longer **served** by anything — they are just
files. `foundation/` sits two directories from `ambient/` and **no arrow connects them**;
that absence is invariant A-9, drawn.

Full treatment of MCP's remaining role is §6.2; of the connector's withdrawal, §8.
### 6.4 What dies

| Artifact | Why |
|---|---|
| `neeve/prompts/` + `prompts_sync.sh` | 9 files, 89 lines. Validated by CI, installed nowhere. |
| `context_render.py`'s `OUTPUT_FILES` + 4 of 6 render functions | Dead; kept alive only by their own tests. |
| ~400 of the 469 ambient lines | Move 2 — become files read on demand. |
| Most of the 5-way skill fan-out | §6.3 — same bytes, five paths. |
| The ~84-line product-overview block (16-repo table + K8s runbook) | Splits: narrative → `foundation/products/`; repo table → `registry/repos.yaml`; runbook → that repo's own `.help/`. |
| `neeve/foundation.md`, `products/*/context/` as **rendered** house-rules sources | The *content* survives as `foundation/` (D5); what dies is its rendering into always-on context. Restructure, not extraction. |
| `shared_refs_sync.sh`'s physical duplication | A workaround for zip self-containment that a plugin format removes. |
| **The entire two-channel distribution problem** | §7 — an artefact of supporting a browser population. Org-library ZIPs, `PUBLISHED.yaml`, the manual-publish drift problem, and the 200-character description cap all go with it. |
| **`neeve-context`, the planned MCP server** | §8 — ~1,700 lines of specification, a separate repo, a deploy pipeline, an auth model, and an on-call rotation, in exchange for what a file read and a git hook already do. |

### 6.5 North-star metric

> **What fraction of our rules are Blocked or Surfaced rather than Advised?**

Measurable, honest, and nothing more than the repo's own stated philosophy actually
applied to itself. Secondary metrics: ambient-block line count (target ~40), and
percentage of skills with at least one passing eval case.

---

## 7. One surface, three populations

claude.ai is explicitly out of scope. PMs, designers, and engineers all use **Claude Code** —
the desktop app for those who don't live in a terminal, the CLI or an IDE extension for those
who do. That single fact removes most of what this section used to contain.

### 7.1 What one surface buys

| | Consequence |
|---|---|
| Everyone has a filesystem | The QUERY channel collapses into a file read (§6.1) |
| Everyone has git | **`Blocked` enforcement is uniform** — same pre-commit hooks, same CI, every population |
| Everyone gets plugins | One distribution channel, with `enabledPlugins` for per-person scoping |
| Everyone gets the ambient plane | Per-discipline ambient blocks matter *more*, not less |
| Nobody is browser-only | No org library, no skill ZIPs, no publish API problem, no 200-character description cap, no manual-upload drift |

An earlier version of this document spent a long section on two distribution channels with
opposite properties — one automatable but per-user, one centrally pushed but manual and
unscopable. That whole problem was an artefact of supporting a browser population. It is gone.

### 7.2 The discipline split is now the primary rationale

Three populations share one ambient plane. Today a UX designer opening Claude Code receives
`mypy --strict`, `pytest --cov-fail-under=95`, and *"never import infrastructure concerns
into the domain layer"* as **mandatory, precedence-winning** rules. A PM receives the same,
plus a 16-repo table and a Kubernetes runbook.

With one surface there is no workaround and no separate channel to hide behind.
**Per-discipline context is the only fix**, which promotes Move 2 and the discipline packing
from good hygiene to the point of the exercise.

### 7.3 Enforcement, uniform but substrate-dependent

Every population commits to git, so every population is gated identically:

| Tier | Mechanism | Available to |
|---|---|---|
| **Blocked** | Deterministic check prevents the bad state | **All three**, via pre-commit and CI |
| **Surfaced** | Gap made loud at the moment of work | hooks, warnings, TODO markers, stale-SHA flags |
| **Advised** | Prose a model reads and may follow | ambient block, skill bodies |

The split that remains is by **substrate, not population**: a markdown PRD in a git planning
repo is gated by a CI linter — genuinely `Blocked`. The same PRD authored as a Confluence page
cannot be gated, because CI can't read a wiki reliably in a headless run (A-3). It tops out at
`Surfaced`. That is the real cost of the Confluence choice, and it is a decision to make
deliberately rather than inherit.

### 7.4 The risk this creates

**Onboarding cost for non-engineers on a developer-shaped surface.** Claude Code desktop
assumes a development environment. If a PM or designer can't get through installation and
cloning, they don't use the framework at all — a worse failure than any context gap, and
worse than the browser problem the connector was meant to solve.

**Mitigation: the workspace provisions itself.** A committed `.claude/settings.json` carrying
`extraKnownMarketplaces` + `enabledPlugins` auto-registers and enables the right discipline
plugin **on folder trust** — no marketplace URL to paste, no `/plugin` commands. Setup becomes:
install the app, clone one repo, trust it. Their skills, their ambient block, and their default
agent all arrive with the clone.

That makes the generalized `init_workspace.sh` the highest-leverage onboarding artifact in the
programme — it is what hides a developer surface behind a single clone. Three workspace kinds:
code repo, planning repo, design space.

---

## 8. No bespoke connector

An earlier version of this document argued for building `neeve-context`, an MCP server, and
sequenced it first. **That is withdrawn.** The justification depended almost entirely on a
browser population, and with claude.ai out of scope the scorecard collapses:

| Original justification | Survives? |
|---|---|
| Serves both surfaces | No — there is one surface |
| Only grounding channel for users with no filesystem or git | No — every population has both |
| Only path to `Blocked` on the web | No — CI and pre-commit reach everyone |
| Freshness by construction | No — a clone plus the SessionStart pull already does this |
| Governed writes with validation | No — a pre-commit linter on a git planning repo is deterministic and needs no service |
| Append-only audit trail | No — **git is the audit trail**, with better properties |
| Ends process-definition duplication | No — `process/` in git does that |
| Cross-repo grounding | **Partially** — see §8.2 |

### 8.1 What it would have cost

A service with an uptime obligation, an auth model, a secret store, a deploy pipeline, an
on-call owner, a new internet-facing authenticated surface holding an aggregate of internal
knowledge, and a prompt-injection vector — in exchange for capabilities that a file read and a
git hook provide.

It also introduced the only asymmetric failure mode in the design: with a service in the read
path, one population lost everything on an outage while another degraded gracefully. Removing
it removes the asymmetry, which is the larger architectural win — ahead of the saved build
effort. See `ARCHITECTURE.md` §12.

This is invariant **A-10**: prefer a file in a clone, then an existing connector, then nothing.

### 8.2 What still needed solving — cross-repo intel

The one justification that partly survived. An engineer's question often spans repos, and
`repo-intel` scans one. Two distinct things were conflated under "multi-repo intel":

**(a) An aggregation of the per-repo books.** Each `.help/` book is authoritative for its own
repo. A second copy elsewhere either drifts or must be generated — and if you're generating,
generate into a local directory, where it is greppable, offline, and CI-readable. A scheduled
**aggregation job**, not a service.

**(b) Genuinely cross-repo knowledge that no single repo owns** — how auth flows across three
repos, which repos share a contract, the deployment topology as a whole. **This had no home at
all.** It is now Layer 02½, `cross-repo/` in git, with the freshness contract that makes it
trustworthy:

```markdown
# Cross-repo: auth flow, robin-ai → robin-web → one-portal

verified-against:
  robin-ai:   a1b2c3d
  robin-web:  e4f5g6h
  one-portal: i7j8k9l
```

A scheduled check flags entries whose referenced repos have moved past the recorded SHAs —
reusing the manifest-hash pattern `pre-commit-context-sync` already implements. Without that,
`cross-repo/` becomes the wiki page that was accurate in March, which is exactly the failure
this framework exists to make loud.

**Confluence was considered for (b)** and is defensible for human-collaboration artifacts —
PRDs and design docs read by stakeholders outside engineering. It is the wrong home for
agent-grounding material: no freshness contract, unreadable by CI, and a softer
prompt-injection surface than a reviewed file. The split that results is coherent —
**agent-grounding material in git; human-collaboration artifacts wherever the humans are.**

### 8.3 The gap that remains

`cross-repo/` has no authoring path yet, and a knowledge store nobody writes to stays empty
regardless of where it lives. The fix is a cross-repo mode for `repo-intel` — *"trace this
contract across every repo that touches it, and record the finding with the SHAs you verified
against."* A skill change, not infrastructure.

### 8.4 Trigger condition for revisiting

If a population appears that cannot install anything — browser-only by policy or by role — a
connector is the only path to serving them, and this is the decision to reopen. The design
detail is preserved in `superseded/connector/**` rather than needing to be rebuilt. Do not
build for it speculatively.

## 9. Relationship to `implementation-plan.md`

The plan is now at v3 and reflects everything below. Fate of each original element:

| Plan element | Fate |
|---|---|
| Phase 0 (truncate bug, refresh-loop escalation, uninstall path, CI gap) | **Survives untouched** — bugs regardless of architecture |
| D1 — discipline membership declared in frontmatter | **Survives** |
| D2 — never rename the default agent `neeve` | **Survives** — still the worst latent hazard |
| D3 — discipline plugins | **Survives** |
| D4 — two planes, different mechanisms | **Survives and sharpens** |
| Plugin packaging | **Survives** as the single distribution answer |
| Split the 469-line payload three ways | **Superseded.** Shrink to ~40 lines first (Move 2), then scope |
| Three discipline packs | **Survives, and is now the primary rationale** (§7.2) rather than one move of five |
| Enforcement tiers, evals, corrections aggregation | **Added** — absent from v1 |
| Connector-first ordering | **Withdrawn entirely** (§8). Track B deleted |
| Two-channel web surface work | **Withdrawn** (§7) — org-library ZIPs, checksummed publish manifest, 200-char description cap |
| — | **Added:** cross-repo intel with a freshness contract (§8.2); workspace self-provisioning as the onboarding answer (§7.4) |

**Current order:** land docs → two cheap spikes → safety fixes → registry → process-as-data →
ambient shrink → flatten/rename → foundation + cross-repo → surfaces → evals. Roughly 4–6
weeks, down from 6–8, because §7 and §8 removed more work than they added.

---

## 10. Validation required before committing

Four things this proposal rests on that are not yet established. The first two are staffing
questions, which is the honest characterisation of the biggest risk here — the missing pieces
are content and adoption, not engineering.

1. **Can a PM and a designer actually complete setup on Claude Code desktop?** It assumes a
   development environment. If they can't get through install-and-clone unassisted, the
   framework has no non-engineering users regardless of how good its context is. **Now risk
   #1**, and it replaces the browser gap the connector was meant to close. Half a day to test:
   watch one of each do it, and don't help.
2. **Real product and design stage gates, authored by a PM and a designer.** The seam can be
   built without them; the content cannot. Inventing it would produce exactly the
   confident-and-wrong artifact this framework exists to prevent — and it now blocks two live
   populations rather than deferring a hypothetical.
3. **Does the agent read the file when the routing block points at it?** The whole Pull channel
   turns on this. Cheapest test: take one currently-pushed fact — the repo registry — put it in
   a file, cut it from the ambient block, leave only a pointer, and measure read-versus-guess.
   Cheaper than it was in the connector design: no server to stand up. If it guesses even with
   good pointers, Move 2's ceiling is well above ~40 lines.
4. **Does the ambient block change behaviour at all?** Run a fixed task set with and without
   it. If the delta is small, Move 2 is urgent rather than merely safe. If it's large, find out
   *which* lines carry the effect before deleting 400 of them.

Dropped from this list: everything that depended on the connector — availability ownership,
write-path bypass closure, audit design, MCP prompt UX, and commercial-vs-government admin
surface parity.

## 11. Open questions

### Carried forward

- Does shrinking ambient context to ~40 lines degrade behaviour in tools with weaker skill
  auto-triggering? Copilot has no auto-routing for agents and Codex requires explicit
  invocation, so the block may be doing more work there than in Claude Code. A per-tool
  ambient budget may be necessary.
- Is `AGENTS.md` genuinely read by Copilot, Cursor, and Codex at the paths we would write?
  Those cross-tool claims traced to third-party write-ups, not vendor docs. **Verify before
  betting the mechanism on it.**
- Should `products/*/` become an install-time selection axis? Today one product's 16-repo
  table and Kubernetes runbook ship globally to everyone, including engineers not on that
  product. (Partly answered by `registry/` plus `foundation/products/`, but the selection
  question stands.)
- Who owns the process artifact once it is unbundled? It needs a cross-functional owner, and
  a framework cannot manufacture one.
- **Offline story is now trivially good** — everything except live state is in a clone. Worth
  stating only because an earlier draft treated it as a hard problem.

### Resolved by the 2026-09-02 decisions

- ~~Is there a browser-based Claude Code surface?~~ Moot — claude.ai is out of scope entirely,
  and Claude Code desktop covers the non-terminal populations.
- ~~Does the 200-character description cap degrade auto-invocation?~~ Moot — no org-library
  publishing, so no cap.
- ~~How do MCP prompts surface in the claude.ai UI?~~ Moot.
- ~~Commercial vs government admin-surface parity?~~ Moot — no connector to administer.
- ~~Who carries the pager?~~ Moot — no service (§8.1).
- ~~Can the raw Confluence write path be blocked per group?~~ Moot as an enforcement question;
  the substrate choice below replaces it.

### Still open

- **Product and design workflow content.** `process/workflow.yaml` encodes an eight-stage
  engineering loop; `disciplines/design/` has no ambient block. Both now block live
  populations and need named authors — a PM and a designer. **The largest dependency in the
  programme, and it is not an engineering one.**
- **Onboarding on a developer-shaped surface** (§7.4). Untested. Gated by watching one PM and
  one designer set up unassisted.
- **PRD and design-doc substrate: Confluence or a git planning repo?** Determines the
  enforcement ceiling for those artifacts — `Surfaced` versus `Blocked` (§7.3). Split answer
  is defensible: agent-grounding material in git, human-collaboration artifacts where the
  stakeholders read them.
- **Authoring path for `cross-repo/`** (§8.3). A store nobody writes to stays empty; the fix
  is a cross-repo mode for `repo-intel`.
- Is losing a `dist/` drift check acceptable, or should marketplace entries point at repo
  subdirectories? Unverified.
- Does `ambient/core.md` need a per-surface variant? Codex and Cursor do not auto-route to
  agents, so the block may carry more weight there than in Claude Code.