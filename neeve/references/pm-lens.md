# PM Lens — Checklist for Any Spec or Feature Request

Referenced by `to-spec` (Stage 4 of the Design Loop, see `neeve/README.md`)
and `to-prd` (Stage 1). The technical spec-review rubric is thorough on
scope discipline and technical accuracy, but it doesn't independently ask the
PM-shaped questions: who is this for, what does it save them, what happens
when we need to turn it off for one customer. Apply this checklist before or
alongside the technical review, on any spec or feature request that reaches
a customer. Full reasoning: `engineering-principles.md` § PRD & Scoping
Principles.

## Checklist

1. **Named outcome, not internal capability.** Can you name the buyer
   persona (facilities director, security operations lead, OT integrator —
   see `foundation.md`) and the specific operational outcome (fewer
   truck-rolls, faster incident triage, an auditor's question answered in
   one click)? If the spec only describes a capability with no named
   beneficiary, send it back before implementation proceeds.
2. **Enterprise requirements checked now, not deferred.** For anything
   touching auth, access control, or configuration change: is SSO/SAML,
   RBAC, audit logging, or data residency deferred to "v2" or "enterprise
   tier"? For Neeve's actual customer base, that's usually a launch blocker
   being mislabeled as a nice-to-have — challenge it explicitly. If the
   spec's claim about how SSO/SAML, RBAC, or a compliance standard actually
   works rests on a remembered belief rather than a checked fact, invoke
   `debug-trace` to research it before accepting the claim — a wrong
   assumption about an enterprise standard surfaces only after a real
   enterprise buyer's security review, not before.
3. **Staged rollout and rollback story.** Does the spec name a pilot →
   limited GA → full GA path? Is there an explicit answer to "how do we turn
   this off for one customer without turning it off for all of them"? This
   matters more for Neeve than most SaaS because Robin's actions can reach
   real building equipment.
4. **Scope discipline.** Is anything in the spec answering a question nobody
   asked? Scope bleed is a PM failure mode, not just something spec-review
   catches after the fact.
5. **Business/operational stakes and gaps stated, not implied.** Per
   `context/fragments/production-consequence-and-gaps.md`, does the spec
   or PR description name the operational consequence (downtime, an exposed
   credential, a support cost) *and* explicitly list what's deferred or
   unaddressed, rather than letting it go unstated?

## Output

A short markdown checklist against the five items above, each marked
✅ / ⚠️ / ❌ with a one-line justification — not a full spec rewrite. Flag
anything ❌ as blocking before the spec proceeds to the technical review.
Item 5 must never be marked ✅ with no supporting detail — either the
consequence/gaps are named, or the item is ⚠️/❌.
