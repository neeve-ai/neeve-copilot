# Context Architecture Redesign

Design documents for restructuring how knowledge reaches AI agents across the Neeve
engineering, product, and design teams.

**Status:** proposal, under review. No code has changed.
**Integration branch:** `redesign/context-architecture`

---

## Reading order

Start with the proposal for the argument, then the architecture for the target state. The
other two are reference material.

| # | Document | Answers | Read it when |
|---|---|---|---|
| 1 | [`redesign-proposal.md`](redesign-proposal.md) | **Why** — what's wrong today, and the five moves that fix it | First. It carries the evidence and the reasoning |
| 2 | [`ARCHITECTURE.md`](ARCHITECTURE.md) | **What** — the target system, its invariants, and the decision index | Second, or first if you only want the destination |
| 3 | [`implementation-plan.md`](implementation-plan.md) | **How and when** — phases, branches, gates, risks | When planning work |
| 4 | [`directory-redesign.md`](directory-redesign.md) | **Where** — the filesystem, with a complete old→new mapping | When moving files |

**In a hurry?** Two sections carry most of the argument:
`redesign-proposal.md` §4 (the central flaw) and `ARCHITECTURE.md` §2 (the ten invariants).

---

## The problem, in one table

Measured from the repo as it stands, so the proposal can be argued with:

| Observation | Figure |
|---|---|
| Always-on context injected into **every** request, every repo, every user | **469 lines** |
| …strictly engineering-only, unusable by PM or design | ~30% |
| …one product's infrastructure detail (16-repo table + Kubernetes runbook) | ~18% |
| …genuinely role-neutral | ~35% |
| Deterministic enforcement actually reaching a product repo | 1 pre-commit hook, **warn-only** |
| CI assertions about product outcomes (vs. framework self-consistency) | **0 of 9** |

A UX designer opening Claude Code today receives `mypy --strict` and
*"never import infrastructure concerns into the domain layer"* as **mandatory,
precedence-winning** rules. That is the problem this redesign exists to fix.

A second, narrower one: the framework's own contributing guide says product-specific knowledge
*"does not belong in neeve-copilot at all"* — and `to-prd` nonetheless instructs the model to
**refuse** any PRD that doesn't name a commercial-real-estate persona. The rule existed and was
violated because it was advisory. D12 makes it enforced.

---

## Decisions of record

Full index with rationale in [`ARCHITECTURE.md`](ARCHITECTURE.md) §15.

| ID | Decision |
|---|---|
| D1 | Discipline membership declared in skill frontmatter, not directory location |
| D2 | One default agent, `neeve`, **never renamed** — the installer cannot self-heal a rename |
| D3 | Discipline plugins: core · engineering · product · design |
| D4 | Two planes — ambient vs. invocable — with different mechanisms |
| D5 | Layers 04 + 03a live in git, read as files |
| D6 | Process narrative split from executable rules; both in git |
| D7 | **No bespoke connector.** Files in a clone, plus existing Atlassian/AWS connectors |
| D8 | Cross-repo intel in git with a SHA-pinned freshness contract |
| D9 | One surface (Claude Code), three populations |
| D10 | Workspaces self-provision via a committed `.claude/settings.json` |
| D11 | Per-repo book directory `.help/` → **`.neeve/`**, migrated by dual-path fallback |
| D12 | **Product knowledge comes from the workspace.** The harness holds the index, never the content |
| D13 | `ot-building-automation` retired; its domain content migrates into the repos it describes |
| ~~D14~~ | ~~Split content into skill bundles~~ — **rejected**: it orphans the cross-cutting evals |
| D15 | **The plugin is the delivery mechanism.** Consumers install a plugin; they never clone this repo |

---

## Superseded

[`superseded/connector/`](superseded/connector/) holds the PRD, architecture, and engineering
spec for **`neeve-context`** — an MCP server this redesign initially recommended building
first, then withdrew under D7.

Retained deliberately. Someone will propose a service like it again, and the scorecard
showing which justifications died with the browser surface is more useful than a blank page.
Each file carries a withdrawal banner.

---

## What is still open

The two largest dependencies are **not engineering**:

1. **Product and design workflow content.** `process/workflow.yaml` encodes an eight-stage
   engineering loop; the design discipline has no ambient block. Both now block live user
   populations and need named authors — a PM and a designer.
2. **Onboarding on a developer-shaped surface.** Claude Code desktop assumes a development
   environment. If a PM or designer cannot complete setup unassisted, the framework has no
   non-engineering users regardless of how good its context is. Untested.

Two cheap spikes gate the rest of the work — see `implementation-plan.md` §3.
