---
name: to-prd
description: >
  Turns a problem statement into an enterprise SaaS + AI product PRD, led by
  a security-and-operations journey in commercial real estate OT — Neeve's
  actual customer reality — before any other persona. Trigger on: "write a
  PRD for...", "turn this problem into a PRD", "draft a product requirements
  doc for...", "what should we build for...". Stage 1 of the Design Loop
  (see `neeve/README.md`) — upstream of `neeve-dls` prototype mode, `to-erd`,
  and the whole spec pipeline.
---

# To-PRD

## Why This Skill Exists

Neeve sells the security and control layer for smart buildings and critical
infrastructure. A PRD written like a generic B2B SaaS feature request — user
story, acceptance criteria, done — misses the two things that actually
determine whether Neeve's buyer says yes: does this hold up under a security
review, and does it survive contact with a real building's operations team.
This skill writes PRDs that lead with those two questions, using
enterprise-SaaS-plus-AI PRD structure (problem → journeys → success metrics →
requirements → compliance → rollout) as the shape, and Neeve's own culture
(`foundation.md`, `context/base.md` § Why This Matters) as the lens.

This does not replace `neeve/references/pm-lens.md` — that checklist is the
ad hoc *reviewer*, usable against any spec or feature request at any time.
`to-prd` is the *producer*: it writes the PRD in the first place, and applies
`pm-lens.md`'s checklist against its own draft before handing off.

## Producer Contract

A finished PRD must hand off, explicitly, to whatever consumes it next
(`neeve-dls` prototype mode, or `to-erd` directly if there's no UI):

- A stable **feature-slug** (kebab-case, decided once, here) — reused
  unchanged as the prototype's `proto/<feature-slug>` branch name and as
  `to-erd`'s output filename, `robin-adr/erd/<feature-slug>-workitems.md`.
  Do not let this drift between documents.
- An explicit statement of whether a UI prototype is expected. Most
  customer-facing features go through `neeve-dls` prototype mode next;
  backend-only, integration, or infra features can state "no prototype —
  feeds `to-erd` directly" and skip it.
- The Security & Compliance section (below) populated with enough detail
  that `to-erd` can derive a compliance mapping per work item without
  re-deriving it from scratch.

## Core Rules

1. **Clarify before drafting.** Do not write a PRD from a one-line prompt.
   Ask: who specifically hits this problem today, what do they do instead
   right now (the actual workaround), and why now (what changed, what's
   forcing this). If the answer is "an internal capability we want to
   build," not a named outcome for a named persona, push back before
   drafting — this is exactly `pm-lens.md` checklist item 1, applied at the
   point of writing rather than the point of review.
2. **The primary journey is not optional and not generic.** Section 2 below
   must name a specific security-operations or facilities/building-operations
   persona in a commercial real estate OT context, not a placeholder. Refuse
   to finalize a PRD where this section could describe literally any SaaS
   product — if a reviewer can't tell this is Neeve from that section alone,
   it isn't finished.
3. **Enterprise requirements are launch blockers, checked now.** SSO/SAML,
   RBAC, audit logging, data residency — for anything touching auth, access
   control, or configuration, these get their own line in Functional/
   Non-Functional Requirements, not a "phase 2" footnote. This is
   `pm-lens.md` checklist item 2, restated as a drafting instruction rather
   than a review-time catch.
4. **Security & compliance is a first-class section, not an appendix.**
   Every PRD gets a Security & Compliance Considerations section (item 8
   below), even when the honest answer for a given sub-point is "not
   applicable to this feature" — an explicit "not applicable" is acceptable;
   a missing section is not.
5. **State consequence and gaps, every time.** Section 9 below is not a new
   invention — it is `context/fragments/production-consequence-and-gaps.md`'s
   discipline (production consequence: what breaks, who notices, blast
   radius, rollback story; gaps: named as line items, never silent),
   applied to a PRD instead of a spec or a code review. Read that fragment
   before drafting this section if it's been a while.
6. **Scope discipline.** Anything answering a question nobody asked is scope
   bleed, a PM failure mode as much as an engineering one — cut it, don't
   footnote it as "nice to have while we're here."
7. **Check the freshness of the source itself before relying on it.** This
   skill's own instructions, `pm-lens.md`'s checklist, and the
   production-consequence fragment all live in a locally-cloned
   `neeve-copilot`. On Claude Code, a global `SessionStart` hook keeps that
   checkout current automatically (see `neeve/products/robin/README.md` §
   "Keeping It Fresh"); no equivalent is confirmed for Copilot, Cursor,
   Codex, or Antigravity. If freshness can't be confirmed, say so in the
   PRD's handoff line rather than silently assuming the local checkout is
   current.
8. **Ground enterprise/compliance claims for real, don't recall them.** If a
   Functional or Enterprise Requirement rests on how SSO/SAML, RBAC, a
   compliance standard, or a third-party integration actually behaves,
   invoke `debug-trace` to research it rather than stating a remembered,
   possibly-outdated belief as fact — a PRD requirement built on a wrong
   assumption about how an enterprise standard works ships that wrongness
   into every downstream work item `to-erd` produces from it. Include the
   **Depth check** line (`debug-trace`'s Disclosure Requirement) in Section 9
   (Operational Consequence & Gaps).

## Workflow

**Phase 0 — Clarify.** Confirm the problem, the primary persona, and why
now, per Core Rule 1. Do not proceed past this phase on assumptions.

**Phase 1 — Draft.** Write the full PRD using the Output Template below, in
order. Decide the `feature-slug` here and use it verbatim in the doc's
filename and header.

**Phase 2 — PM lens self-check (mandatory before handoff).** Apply
`neeve/references/pm-lens.md`'s 5-point checklist against the draft. Embed
its ✅/⚠️/❌ output, with one-line justifications, verbatim in the PRD's own
`## PM Review` section (item 13 below) — do not summarize or paraphrase the
checklist itself into this file; point at it.

**Phase 3 — Handoff statement.** State plainly, as the PRD's last line,
whether this goes to `neeve-dls` prototype mode next or straight to
`to-erd`, and the `feature-slug` to carry forward.

## Output Template

Write to `robin-adr/prds/<feature-slug>.md`:

```markdown
# PRD: <Feature Name>

**Feature slug:** `<feature-slug>`
**Status:** draft | reviewed | approved
**Prototype expected:** yes → neeve-dls prototype mode | no → straight to to-erd

## 1. Problem & Opportunity

What's broken or missing today. Why now — what changed, what's forcing
this conversation.

## 2. Primary Journey: Security/Operations in Commercial Real Estate OT

The specific security-operations or facilities/building-operations persona
(e.g. a building security operations analyst, a facilities/BMS operations
manager, an OT integrator) who hits this problem, the operational outcome
they need, and what they do today without this feature. This section must
not be generic — name the persona and the real building/security context.

## 3. Secondary Personas & Journeys

Any other users this serves, explicitly marked secondary to Section 2.

## 4. Success Metrics

Adoption metrics, operational KPIs (fewer truck-rolls, faster incident
triage, an auditor's question answered in one click), and security-posture
metrics where relevant.

## 5. Scope

**In scope:** ...
**Out of scope:** ...

## 6. Functional Requirements

## 7. Enterprise Requirements (Launch Blockers, Not Deferred)

SSO/SAML, RBAC, audit logging, data residency — state each explicitly as
in-scope-now or genuinely not-applicable-to-this-feature. Never "phase 2."

## 8. Security & Compliance Considerations

- Relevant frameworks, where applicable: SOC 2 (Trust Service Criteria),
  NIST CSF, IEC 62443 (zones/conduits — for anything touching physical/OT
  systems).
- Data classification of anything this feature touches.
- Zero-trust framing: does this introduce a new trust boundary, credential,
  or network path? (see `foundation.md` / `context/base.md` § Why This
  Matters)
- If none of the above genuinely applies, say so explicitly rather than
  omitting the section.

## 9. Operational Consequence & Gaps

Per `context/fragments/production-consequence-and-gaps.md`: what breaks
or degrades if this is wrong, who notices, blast radius, rollback/kill-switch
story — and a **Gaps** list (named, not silent) of anything not yet
addressed (a control not yet implemented, a rollout gate not yet defined).

## 10. Staged Rollout & Rollback

Pilot → limited GA → full GA. Explicit answer to: can this be turned off
for one customer without turning it off for all of them?

## 11. Dependencies & Risks

## 12. Open Questions

## 13. PM Review

`neeve/references/pm-lens.md`'s 5-point checklist output, embedded verbatim
(✅/⚠️/❌ + one-line justification per item) — see Workflow Phase 2.

---

**Handoff:** feature-slug `<feature-slug>` →
[neeve-dls prototype mode | to-erd directly]
```

## Reference Files

| File | When to load |
|---|---|
| `neeve/references/pm-lens.md` | Always, for the Phase 2 self-check — never duplicate its checklist text into a PRD, reference it |
| `context/fragments/production-consequence-and-gaps.md` | Always, for Section 9 |
| `neeve/foundation.md`, `context/base.md` § Why This Matters | For Section 8's zero-trust framing |
| `code-review/references/security.md` | When Section 8 needs deeper security-framework grounding than a PM-level pass covers |

---

## Skill Chain

**Prior:** none — this is the top of the Design Loop; entry point is a
problem statement, not another skill's output.

**Feeds into:** `neeve-dls` (PRD Prototype Mode) if a UI prototype is
expected, otherwise directly into `to-erd`.

**Feeds into (always, eventually):** `to-erd` → `to-spec` →
`implement-spec` → `code-review` — the existing, unmodified pipeline.
