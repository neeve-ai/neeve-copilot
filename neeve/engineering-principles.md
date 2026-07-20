# Neeve Engineering Principles

Layer 03 of the 4-Layer Context stack (see `neeve/README.md`) — the SDLC
process principles that govern every stage of the Design Loop (PRD → Design →
ERD → Spec → Implement → Code Review → Merge → CI Pass, see `neeve/README.md`
Pillar 3). This is the source document the `to-prd`, `to-erd`, `to-spec`,
`implement-spec`, `code-review`, and `neeve-dls` skills — and the unified
`neeve` agent — condense their operating instructions from. Edit here first
when a principle changes, then update the affected skill(s) to match; one
source, rendered/condensed outward, the same discipline `context/base.md`
uses for per-repo instructions.

Everything below is written against Neeve's actual offering and customers
(see `foundation.md`), not generic SaaS advice.

---

## PRD & Scoping Principles

**Working backwards from the operator, not the capability.** Before scoping
a feature, write the customer-facing outcome first — a named enterprise
buyer persona (facilities director, security operations lead, OT integrator)
and a named operational outcome (fewer truck-rolls, faster incident triage,
an auditor's question answered in one click), not an internal capability. A
spec that can't state whose day gets better and how is not ready for
`to-spec`.

**Enterprise buyer requirements are launch blockers, not a phase-2
checklist.** SSO/SAML, RBAC, audit logging, data residency, and tenant
isolation are not "enterprise tier" bolt-ons to design in later — for
Neeve's actual customer base (regulated real estate, healthcare,
transportation), these are launch blockers. A PRD that defers audit logging
to "v2" for a feature touching access control or configuration change should
be challenged, not waved through.

**Staged rollout with a rollback story is mandatory, not an operational
afterthought.** Because Robin's actions can reach real HVAC/lighting/
access-control equipment, every customer-facing feature needs an explicit
staged-rollout plan (pilot site → limited GA → full GA) and an explicit
rollback/kill-switch story — "how do we turn this off for one customer
without turning it off for all of them" is a required PRD/spec question.

**Scope discipline is a PM failure mode, not just a spec-review catch.** The
spec-review "Scope Bleed" check exists because undisciplined scope creep is
as much a PM failure as an engineering one — greenlighting "just one more
thing" into a spec is the same failure as an engineer adding it unasked.

---

## Design Principles

**Pixel-perfect design-system fidelity, no exceptions.** Every
customer-facing surface matches `dls-neeve` exactly — typography, spacing,
color, icons, states — because for an enterprise buyer evaluating a security
product, visual inconsistency reads as engineering inconsistency, and
engineering inconsistency reads as a reason not to trust the product with
critical infrastructure. "Close enough" is a design defect here, not a
tradeoff.

**Accessibility is a compliance surface, not a nice-to-have.** Missing focus
states, missing alt text, and insufficient color contrast are launch
blockers for anything a facilities operator uses during an incident — a
VPAT/WCAG 2.1 AA gap is a routine enterprise security-questionnaire line
item, and an accessibility failure during an actual building emergency is a
safety issue, not just a compliance one.

**Design the failure state before the happy path.** For any UI surfacing
live building data (alarms, point values, overrides), the stale/fault/
disconnected state is not an afterthought skin on the happy-path design —
design it first, since an operator misreading a stale value as current can
have real operational consequences.

---

## Spec & Architecture Principles

**Spec first — the spec owns scope, sequencing, interfaces, and
invariants.** Component & data-flow diagrams and SOLID design patterns are
locked before implementation, not discovered during it. For non-trivial
changes, the SDLC path is `to-prd` (if greenfield) → `to-erd` → `to-spec` →
human review → `implement-spec` → `code-review`; do not skip straight to
implementation.

**Reuse first.** Verify no existing component covers the need before
creating a new class, service, table, or helper. Duplicate helpers and DTOs
are a design failure, not a style nit.

**Contract boundaries matter.** Protocols, DTOs, OpenAPI schemas, event
payloads, and typed value objects are not optional decoration.

---

## Implementation Principles

**Behaviour over ceremony.** Tests prove user-visible or system-visible
behavior, not that a mock was called. Every test traces to an FR, acceptance
criterion, or user journey. Coverage target: ≥95% line and branch on changed
modules — the enforced number, not an aspiration (`references/quality-gates.md`).

**No speculative code.** Only implement what the current task requires.
Code added "just in case" is debt on day one.

**Deployment reality matters.** If code changes runtime shape — env vars,
health endpoints, ports, metrics, background workers, singleton assumptions
— the Helm/Kubernetes layer must be checked before the task is done.

**Zero-trust by default.** No new trust boundary should assume perimeter
safety; every credential is short-lived and scoped by default. Internal
service-to-service traffic authenticates — "it's inside the VPC" is not a
security control. The codebase is held to at least the bar Neeve sells.

**Responsible-AI staged exposure for agentic actions.** Any capability that
can take a real-world action (a setpoint override, a schedule change) ships
read/query-only first and earns write/action capability only after a
deliberate, reviewed staging decision.

---

## Review & Merge Principles

**Compliance-as-code, continuously verified.** Prefer an automated,
CI-enforced check over a manually-attested control wherever one can exist —
the reasoning behind `context-drift-check`, `spec-review.yml`, and the
Security Gates section in `references/security.md`: a control that isn't
continuously verified is a control that silently rots.

**Forward-deployed proximity to the actual failure mode.** For OT surfaces
specifically (Niagara/BQL/WebCTRL), ground decisions in what the actual
field deployment does (see the `ot-building-automation` skill's in-repo
sources) over what a generic best practice would suggest.

**Error budgets over ad hoc firefighting.** Reliability work is prioritized
against an explicit budget for the surfaces that matter operationally
(building-connectivity uptime, alarm-delivery latency), not purely
reactively. A repo touching a customer-facing SLO-bearing surface should
have that SLO written down somewhere discoverable.

**Blameless postmortems, mechanism not memory.** When something breaks —
especially anything touching a live building system — the postmortem is
about the mechanism that let it happen (a missing gate, an untested edge
case, a spec gap) and how to make the *next* instance structurally harder,
not about who wrote the line.

**State production consequence and gaps, every time.** Every skill's
output — a spec, a review, an implementation summary, a design change —
must name what breaks if this is wrong, who notices, blast radius, and
rollback story; and must list what's *not* covered (a missing test, a
missing security control, a missing CI gate) as an explicit line item, never
a silence. Full discipline:
`context/fragments/production-consequence-and-gaps.md`. A blank space
where this section belongs is itself a finding on the output.

---

## Working Memory & Decision Capture

Every product repo's OKF book (Layer 02, `.help/introduction.md` /
`index.md` / `appendix.md` / `memory.md` / `lessons.md`, scaffolded by
`init-repo.sh` and maintained by `repo-intel`) includes two files that
capture facts no code scan can derive: durable working state and past
corrections. **Any skill, mid-task — not just `repo-intel`** — routes a fact
to the right home the moment it's learned, rather than letting it evaporate
at the end of the conversation:

- **A correction** (the user points out a mistake) → append a terse
  mistake → rule pair to that repo's `.help/lessons.md`.
- **A durable operational quirk or current-state fact** (something learned
  during work that isn't code reference and would help a later session) →
  append it to that repo's `.help/memory.md`, keeping it within its bounded
  ~2,500 char budget — consolidate, don't hoard.
- **A durable architectural decision** (choosing between competing
  approaches, adopting/replacing a dependency, a convention future work must
  follow) → an ADR via the `rca-retro-adr` skill's ADR mode, filed at
  `docs/adr/ADR-NNNN-<slug>.md` — the same location and template
  `repo-intel`'s retrospective ADR stubbing already uses. One ADR home per
  repo, not two.
- **An incident or bug already resolved** → the `rca-retro-adr` skill's RCA
  mode, filed at `.help/reports/rca/` — the mechanism this charter's
  "Blameless postmortems, mechanism not memory" principle above points to.
- **Verbose code/system reference** → the existing three book files
  (`introduction.md`/`index.md`/`appendix.md`), never `memory.md`/
  `lessons.md` — those two never duplicate what the other three already
  cover.

A full `repo-intel` pass is still the place to consolidate and prune
`memory.md`/`lessons.md` when they've drifted or grown past budget — but
day-to-day appends don't wait for that pass.

---

## How This Charter Is Used

The `to-prd`, `to-erd`, `to-spec`, `implement-spec`, `code-review`, and
`neeve-dls` skills each condense the relevant section above into their own
operating instructions, and the unified `neeve` agent's routing table
(`agent/neeve/AGENT.md`) enforces the sequencing across all of them.
`rca-retro-adr` and `repo-intel` carry out this charter's "Working Memory &
Decision Capture" section specifically. Edit this file when the underlying
principle changes, then update the affected skill(s) to match.

For a customer-facing feature end to end, the intended sequence pulls in
multiple skills, not just one:

```
to-prd / to-spec         ← is this the right thing, for the right persona, scoped right
      ↓
neeve-dls                ← (if UI) DLS fidelity + accessibility + failure-state design
      ↓
implement-spec           ← build it; quality gates (references/quality-gates.md)
      ↓
code-review              ← general engineering review + mandatory security pass
                            (references/security.md) when the surface warrants it
```

Not every change needs every stage — a small bug fix doesn't need `to-prd`,
and a backend-only change doesn't need `neeve-dls`. Use judgment about which
stages apply, the same way `spec_based_development` is opt-in per repo.
