# Neeve Product, Design & Engineering Charter

This is the source document the org-wide agents in `agents/` (and, once
promoted, `.github/agents/`) are condensed from. It exists so the *why*
behind each agent's behavior is written down once, in one place, instead of
re-derived per agent or per reviewer.

Neeve builds the security and control layer for smart buildings and critical
infrastructure: Secure Link/Secure Edge (zero-trust remote access), Cloud BMS,
Edge Intelligence, Robin (agentic AI for building operations), and an App
Marketplace for containerized OT applications — serving commercial real
estate, industrial OT, healthcare, and transportation customers. Everything
below is written against that offering, not as generic SaaS advice.

Each section below adapts a specific, named practice lineage from companies
that are strong on the dimension in question — adapted to Neeve's actual
product and customers, not copied wholesale. Where a practice doesn't fit
Neeve's stage or shape, it's noted as such rather than force-fit.

---

## Product Management

**Working Backwards, adapted (lineage: Amazon PR-FAQ).** Before scoping a
feature, write the customer-facing outcome first — for Neeve, that almost
always means a named enterprise buyer persona (facilities director, security
operations lead, OT integrator) and a named operational outcome (fewer
truck-rolls, faster incident triage, an auditor's question answered in one
click) — not an internal capability. A spec that can't state whose day gets
better and how is not ready for `to-spec`.

**Enterprise buyer requirements are first-class, not a phase-2 checklist
(lineage: Okta/Auth0, identity-first enterprise SaaS).** SSO/SAML, RBAC,
audit logging, data residency, and tenant isolation are not "enterprise
tier" bolt-ons to design in later — for Neeve's actual customer base
(regulated real estate, healthcare, transportation), these are launch
blockers, not follow-up tickets. A PM spec that defers audit logging to "v2"
for a feature touching access control or configuration change should be
challenged, not waved through.

**Staged rollout with a rollback story (lineage: Anthropic/OpenAI staged
model launches, adapted to physical infrastructure).** Because Robin's
actions can reach real HVAC/lighting/access-control equipment, every
customer-facing feature needs an explicit staged-rollout plan (pilot site →
limited GA → full GA) and an explicit rollback/kill-switch story — "how do we
turn this off for one customer without turning it off for all of them" is a
required spec question, not an operational afterthought.

**Say no to scope bleed as a PM discipline, not just a spec-review
mechanism.** The `to-spec`/spec-review "Scope Bleed" check exists because
undisciplined scope creep is a PM failure mode as much as an engineering one
— a PM greenlighting "just one more thing" into a spec is the same failure
as an engineer adding it unasked.

---

## Design

**Pixel-perfect design-system fidelity, no exceptions (lineage: Stripe/Linear
design craft bar, already codified in the `neeve-dls` skill).** Every
customer-facing surface matches `dls-neeve` exactly — typography, spacing,
color, icons, states — because for an enterprise buyer evaluating a security
product, visual inconsistency reads as engineering inconsistency, and
engineering inconsistency reads as a reason not to trust the product with
critical infrastructure. "Close enough" is a design defect here, not a
tradeoff.

**Accessibility is a compliance surface, not a nice-to-have (lineage:
enterprise SaaS procurement — VPAT/WCAG 2.1 AA is a routine enterprise
security-questionnaire line item).** Treat missing focus states, missing
alt text, and insufficient color contrast as launch blockers for anything a
facilities operator uses during an incident — accessibility failures during
an actual building emergency are a safety issue, not just a compliance one.

**Design the failure state before the happy path (lineage: safety-critical
UX practice, adapted for OT).** For any UI surfacing live building data
(alarms, point values, overrides), the stale/fault/disconnected state is not
an afterthought skin on the happy-path design — design it first, since an
operator misreading a stale value as current can have real operational
consequences.

---

## Engineering

**Zero-trust by default (lineage: Okta/BeyondCorp, already Neeve's own
product thesis for Secure Link/Secure Edge — the bar we hold our own code to
should be at least the bar we sell).** No new trust boundary should assume
perimeter safety; every credential should be short-lived and scoped by
default. Internal service-to-service traffic authenticates — "it's inside
the VPC" is not a security control.

**Error budgets over ad hoc firefighting (lineage: Google SRE).** Reliability
work should be prioritized against an explicit budget for the surfaces that
matter operationally (building-connectivity uptime, alarm-delivery latency),
not purely reactively. A repo touching a customer-facing SLO-bearing surface
should have that SLO written down somewhere discoverable, not implied.

**Blameless postmortems, mechanism not memory (lineage: Google SRE / Etsy).**
When something breaks — especially anything touching a live building system
— the postmortem is about the mechanism that let it happen (a missing gate,
an untested edge case, a spec gap) and how to make the *next* instance of
that failure structurally harder, not about who wrote the line. This is also
why `security.yml`/CodeQL being disabled in `robin-ai` is worth resolving
independent of blame for why it was originally disabled.

**Compliance-as-code, continuously verified (lineage: Vanta/Wiz — continuous
control monitoring instead of point-in-time audits, directly relevant given
Neeve's OT/critical-infrastructure customer base will ask for SOC2/ISO27001
evidence).** Prefer an automated, CI-enforced check over a manually-attested
control wherever one can exist — this is the same reasoning behind
`context-drift-check`, `spec-review.yml`, and the Security Gates section in
the `code-review` skill's `security.md`: a control that isn't continuously
verified is a control that silently rots.

**Forward-deployed proximity to the actual failure mode (lineage: Palantir —
engineering that stays close to how the software is actually used in the
field, especially for mission-critical/regulated deployments).** For OT
surfaces specifically (Niagara/BQL/WebCTRL), prefer grounding decisions in
what the actual field deployment does (see the `ot-building-automation`
skill's in-repo sources) over what a generic best practice would suggest —
this is why that skill is explicitly sourced from `niagara-robin-agent`'s and
the `alc-*` repos' own validated content rather than public docs alone.

**Responsible-AI staged exposure for agentic actions (lineage:
Anthropic/OpenAI red-teaming and staged capability rollout, adapted to
building automation).** Any Robin capability that can take a real-world
action (a setpoint override, a schedule change) should ship read/query-only
first and earn write/action capability only after a deliberate, reviewed
staging decision — matching why `niagara-robin-agent`'s current 12 MCP tools
are all read/query tools, not actions.

---

## How this charter is used

- The org-wide agents in `agents/` (`neeve-reviewer`, `neeve-security-partner`,
  `neeve-pm-partner`, `neeve-design-partner`, `neeve-ot-specialist`) each
  condense the relevant sections above into their operating instructions —
  edit this file when the underlying principle changes, then update the
  affected agent(s) to match, the same "one source, rendered/condensed
  outward" discipline `neeve-copilot`'s `context-src/base.md` uses for
  per-repo instructions.
- This charter does not replace `context-src/base.md`'s "Why This Matters"
  section (zero-trust / simplify / state the stakes) — it's the expanded
  version, with named lineage, for the agents and reviewers that need the
  fuller reasoning rather than the three-bullet summary.
