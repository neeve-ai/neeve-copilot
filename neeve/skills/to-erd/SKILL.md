---
name: to-erd
description: >
  Turns a PRD (plus an optional prototype) into an Engineering Requirements
  Document — a compliance-aware breakdown of atomic, dependency-ordered
  work items, grounded in the actual repo(s) — whose items feed the
  existing, unmodified to-spec pipeline. Trigger on: "break this PRD into
  work items", "write an ERD for...", "turn this into engineering work
  items". Not to be confused with a database Entity Relationship Diagram.
  Stage 3 of the Design Loop (see `neeve/README.md`).
---

# To-ERD

> **Disambiguation:** "ERD" here means **Engineering (Requirements)
> Document** — a work-item breakdown, the output of this skill. Some repos
> also use "ERD" for a **database** Entity Relationship Diagram (an
> unrelated document with the same acronym). If both exist in the same
> org, each should carry a one-line pointer at the other so nobody confuses
> the two.

## Why This Skill Exists

Turning a big feature into a pile of loosely-related tickets is how scope
and dependencies get lost. This skill applies a proven shape — atomic,
dependency-ordered, acceptance-criteria-bearing work items, grouped by
domain, with an explicit dependency graph and sprint ordering — to any
feature coming out of `to-prd`. Two things distinguish it from a plain
work-item breakdown: every item carries a **compliance mapping** (Neeve's
PRDs now carry first-class security/compliance framing that should flow all
the way to the spec each item becomes), and every item is **grounded in the
actual repo(s)**, not just the PRD's prose — real file structure, real
existing patterns, cited, not guessed at.

## Producer Contract

Consumes: a PRD from `to-prd` (with its `feature-slug`), and — if the PRD
called for one — the corresponding `proto/<feature-slug>` prototype branch
from `neeve-dls` PRD Prototype Mode.

Produces: an Engineering Requirements Document for the feature, named
consistently with the same `feature-slug`. **Confirm the write location
with the user before drafting** — don't assume a fixed path; ask where this
org keeps planning docs, or use a location alongside wherever the PRD
itself was written.

Each work item must be citable by a stable `WI-<prefix><NN>` ID and carry
enough detail (`What`, `Key files`, `Acceptance criteria`) that `to-spec`
can start from it without re-deriving scope from the PRD itself.

## Core Rules

1. **One new document per feature, never appended to an existing epic's
   work-item file.** If this org already has a work-item document for a
   different epic, treat it as one instance of the shape, not a shared
   template to keep extending — this feature gets its own file.
2. **Feature-specific prefixes, derived from this feature's own domains.**
   Don't borrow another epic's domain prefixes wholesale. Name each
   prefix's meaning at the top of its section (e.g. "WI-B* — Billing").
3. **An ADR citation is traceability, not a blocker.** If this org tracks
   ADRs and one already covers this feature, cite it. **If none exists,
   don't stop and wait on a human decision** — the PRD (and prototype, if
   any) are the source of truth for scope and rationale here. Note it
   plainly in the Scope header ("Source: PRD `<path>`, no ADR on file")
   and move on. Never invent a citation to a document that doesn't exist.
4. **Ground every work item in the actual repo(s), not just the PRD's
   prose.** Before drafting items, read enough real code/structure in each
   Source-of-Truth repo to write concrete file paths and cite real
   existing patterns — the same "cite files, mark `[inferred]`, never
   invent" discipline `repo-ask`/`repo-intel` already use. A `Key files
   to create/change` list built from guessing at plausible-sounding paths
   is exactly the failure mode this rule exists to prevent. If `repo-ask`/
   `repo-intel` output already exists for a Source-of-Truth repo, use it
   instead of re-scanning from scratch. If a work item's feasibility hinges
   on how a third-party library, framework, or external service actually
   behaves — not just where a file lives — invoke `debug-trace` instead of
   `repo-ask`/`repo-intel`: this is exactly the exhaustive, research-backed
   grounding a work item's `Key files to create/change` and dependency
   claims need before another engineer treats them as reliable.
5. **Compliance is a field, not a section — populate it per item, from the
   PRD, or mark it "N/A."** Every work item gets a `**Compliance:**` line
   (see Output Template) populated from the source PRD's Security &
   Compliance Considerations section. When an item has no
   compliance-relevant surface, write `N/A — no compliance-relevant
   surface`, not a blank. This field is a **pointer for `to-spec` to carry
   forward** — it complements `to-spec`'s existing OWASP-ASVS-based
   `references/security-checklist.md`, it does not replace it.
6. **Dependencies are explicit, both in prose and in a dependency graph.**
   Every item states `**Depends on:**` / `**Blocks:**` (or "nothing"), and
   a mermaid `graph TD` block uses short node IDs (e.g. `R02`, not
   `WI-R02`, inside the graph; `WI-R02` in prose) with edges matching the
   prose dependencies exactly — the two representations must never
   disagree.
7. **Hand off to `to-spec` unmodified — no new fields required there.**
   Map each item's `What` / `Acceptance criteria` / `Key files` directly
   onto `to-spec`'s existing work-item template fields (Goal Check, In/Out
   of Scope, etc.). `to-spec` needs no changes to consume a `WI-*` item.
8. **Check the freshness of the source itself before relying on it.** The
   PRD template's compliance framing and the reference work-item structure
   live in a locally-cloned `neeve-copilot`. On Claude Code, a global
   `SessionStart` hook keeps that checkout current automatically (see
   `neeve/products/robin/README.md` § "Keeping It Fresh"); no equivalent
   is confirmed for Copilot, Cursor, Codex, or Antigravity. If freshness
   can't be confirmed, say so rather than silently assuming the local
   checkout is current.

## Workflow

**Phase 0 — Load inputs and confirm the PRD is current.** Read the source
PRD (and prototype, if any). Confirm the `feature-slug` matches exactly.
Confirm the write location (Producer Contract). Per
`neeve/references/prd-system-of-record.md`, the PRD is the feature's system
of record — before deriving work items, run the decision-state check: is its
`Status:` accurate, are its open questions resolved or explicitly deferred,
does anything already contradict it? If it's stale, reconcile the PRD first
(a logged, committed decision) rather than deriving an ERD from a doc you
know is wrong.

**Phase 1 — Resolve the ADR, without blocking on it.** Per Core Rule 3 —
cite if one exists, note its absence and proceed if not.

**Phase 2 — Ground in the actual repo(s).** Per Core Rule 4: for each
Source-of-Truth repo, read enough real code/structure — actual modules,
existing service boundaries, existing patterns for similar work — to write
concrete `Key files to create/change` entries later, not guesses. Reuse
existing `repo-ask`/`repo-intel` output where available.

**Phase 3 — Derive journeys and domains.** Restate the PRD's success
criteria/personas as "Goal: N User Journeys," and identify this feature's
own domain groups (for prefix assignment, Core Rule 2), informed by the
real repo structure from Phase 2, not just the PRD's abstractions.

**Phase 4 — Write items.** One `WI-<prefix><NN>` per atomic, complete-in-
one-respect deliverable, in the field order from the Output Template. Carry
the PRD's compliance framing into each item's `**Compliance:**` field (Core
Rule 5), and cite real file paths from Phase 2's grounding.

**Phase 5 — Dependency graph and sprint ordering.** Build the mermaid graph
(Core Rule 6) and a sprint-ordering section grouping parallelizable items
by tier (e.g. P1/P2/P3, or week-by-week).

**Phase 6 — Self-check before handoff.** Confirm: every item has a
`Compliance` field (even if N/A), every dependency in prose has a matching
graph edge, every `Key files` entry is either a real path (confirmed in
Phase 2) or explicitly marked `[new file]`, the ADR line reflects Core Rule
3 honestly (cited, or "no ADR on file, PRD is source of truth"), and the
`feature-slug` matches the PRD and (if applicable) the prototype branch
exactly.

**Phase 7 — Write back to the PRD system of record.** If breaking the PRD
into work items changed anything the PRD asserts — split a requirement,
resequenced scope, surfaced a new dependency/risk, or deferred something —
record it back into the PRD per `neeve/references/prd-system-of-record.md`:
edit the affected PRD section, append a **Change & Decision Log** row (Phase
= ERD, with the *why*), advance the PRD `Status:` to `in-erd`, and commit the
PRD change atomically (`prd(<feature-slug>): ERD — <what changed>`) alongside
the ERD. Do not let the ERD silently diverge from the PRD; the PRD stays the
source of truth. If the ERD changed nothing the PRD asserts, still advance
`Status:` to `in-erd` with a log row saying so.

## Output Template

```markdown
# <Feature Name> — Engineering Requirements Document

**Scope:** <ADR citation, or "Source: PRD `<path>`, no ADR on file">
**Epic name:** <feature-slug>
**Sizing:** <e.g. Sprint-level, 1 week per item>
**Source PRD:** <path to the PRD this was derived from>
**Prototype:** <proto/<feature-slug> branch, or "N/A, no UI">

## Source of Truth

| Repo | Path | Role |
|---|---|---|
| ... | ... | ... |

## How to Read This Document

Each work item is atomic and complete in one respect. Items are grouped by
domain. Dependencies are explicit — an item should not start until its
dependencies are done. Every item carries a **Compliance** field: a
pointer for `to-spec` to carry forward, not a replacement for its own
security-checklist pass. Every `Key files` entry is grounded in the actual
repo (Phase 2), not guessed.

## The Goal: N User Journeys

<Restated from the PRD's success criteria/personas, informed by the real
repo structure this feature will actually touch.>

## Dependency Graph

\`\`\`mermaid
graph TD
    <ID>["WI-<ID>: <short title>"]
    ...
    <ID> --> <ID>
\`\`\`

## Decision Items

### WI-D01: <decision needed>

**ADR reference:** <citation, or "none — resolve during implementation">

...

## <Domain Group Name> Work Items (<prefix>)

### WI-<prefix><NN>: <title>

**Repo:** `<repo>`
**ADR:** <citation, or "none on file — PRD is source of truth">
**Compliance:** <framework/control citation, or "N/A — no compliance-relevant surface">
**Depends on:** <WI-* list, or "nothing">
**Blocks:** <WI-* list, or "nothing">

**What:**
<paragraph>

**Key files to create/change:**
- `<real, confirmed path>` — ... (mark `[new file]` if it doesn't exist yet)

**Acceptance criteria:**
- [ ] ...

---

## Sprint Ordering Guide

Items at the same tier can run in parallel. Dependencies flow downward.

### P1 — Must ship

...

## Open Work (Deferred — Not in This Cycle)

...
```

## Reference Files

| File | When to load |
|---|---|
| An existing work-item breakdown from this org, if one exists | For structural precedent — same shape, don't reinvent it per feature |
| This org's ADR source (if any) | For citation (Core Rule 3), never as a blocker |
| The source PRD from `to-prd` | Always — it is the system of record, not just an input; Phase 0 verifies it's current, Phase 7 writes ERD-phase decisions back to it |
| `neeve/references/prd-system-of-record.md` | Always, for Phase 0's decision-state check and Phase 7's write-back/commit discipline |
| Existing `repo-ask`/`repo-intel` output for the Source-of-Truth repos | Always, before Phase 2, if available — don't re-scan from scratch |
| `code-review/references/security.md` | When populating `Compliance` fields needs deeper security-framework grounding than the PRD's own Security & Compliance section provides |
| `to-spec/references/security-checklist.md` | To confirm the `Compliance` field is additive to, not a replacement for, `to-spec`'s own OWASP-ASVS pass |

---

## Skill Chain

**Prior:** `to-prd` (always), `neeve-dls` PRD Prototype Mode (if the PRD
called for a prototype).

**Feeds into:** `to-spec`, one invocation per `WI-*` item — existing,
unmodified pipeline continues from there: `to-spec` → `implement-spec` →
`code-review`.
