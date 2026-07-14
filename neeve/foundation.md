# Neeve Foundation

Layer 04 of the 4-Layer Context stack (see `neeve/README.md`) — what Neeve
is, why it exists, and who it serves. Read this before anything else in this
framework; it's the "why" underneath every judgment call the other layers
ask an engineer or an agent to make. This is the canonical source — cited,
never restated at length — from `engineering-principles.md`, every skill's
production-consequence framing, and the unified `neeve` agent's identity.

## What Neeve Is

Neeve builds the security and control layer for smart buildings and critical
infrastructure. Five product lines, one thesis — zero-trust replaces
perimeter trust for operational technology (OT):

| Product | What it does |
|---|---|
| Secure Link / Secure Edge | Zero-trust remote access + edge-application hosting, replacing VPN-based access into building/industrial systems |
| Cloud BMS | Tridium Niagara-as-a-Service, plus bring-your-own-BMS |
| Edge Intelligence | The data/ML/agentic layer Robin and other apps run on |
| Robin | The agentic AI co-pilot for building operations — this framework's primary consumer today (`products/robin/`) |
| App Marketplace | Containerized OT applications running at the edge |

## Why Neeve Exists

Building operations run on fragmented legacy tooling: VPN-based remote
access (a standing trust liability, and the single most common ransomware
entry point into OT environments), siloed BMS vendors that don't talk to
each other, and manual, un-auditable operator workflows. Neeve's answer:

- **Radical simplicity** — turn fragmented, complicated systems into one
  coherent, managed surface, instead of another point tool to integrate.
- **Zero-trust by default** — assume breach, not perimeter safety; every
  credential short-lived and scoped, every network path authenticated.
- **Edge-cloud hybrid** — real-time control stays at the edge (a building
  safety system cannot tolerate cloud-only latency or availability risk);
  management and intelligence stay centralized and always up to date.

These three are not marketing language — they are the same standard this
framework holds its own code to (see `engineering-principles.md`).

## Who Neeve Serves

Commercial real estate, industrial OT, healthcare, and transportation —
regulated, safety-adjacent, OT-heavy verticals where a wrong deploy has
consequences beyond a support ticket. Named buyer/user personas — use these
in specs and PRDs, not a generic "user" (see `references/pm-lens.md`):

| Persona | What they buy on / act on |
|---|---|
| Facilities director | Owns the building-operations budget and outcomes; buys on cost + uptime |
| Security operations lead / analyst | Owns access-control and incident-response posture; buys on audit trail + zero-trust posture |
| OT integrator | Technical buyer wiring Neeve into an existing BMS/Niagara/WebCTRL estate; buys on integration simplicity |
| BMS / facilities operations manager | The operator who actually uses Robin during a live incident; buys nothing directly, but their trust in the product mid-alarm is what the renewal depends on |

A PRD or spec that could describe any generic SaaS product without naming
one of these personas and a real operational outcome for them is not
finished — see `references/pm-lens.md` and the `to-prd` skill.

## How Neeve Differentiates

- **Zero-trust by default, not VPN-shaped trust** — the bar the codebase is
  held to should be at least the bar sold to customers.
- **Radical simplicity** — prefer removing a special case over adding a flag
  for it; prefer extending an existing integration point over a parallel one.
- **Advisory-first agentic AI** — Robin reads and advises today; it
  deliberately does not submit forms or perform control actions, because its
  actions sit upstream of real HVAC/lighting/access-control equipment.
  Write/action capability is earned through a deliberate, reviewed staging
  decision, not shipped by default (see `engineering-principles.md`'s
  "Responsible-AI staged exposure").

## Why This Shapes Every Piece of This Framework

Code in a Neeve repo often sits between an operator and physical equipment.
Three defaults shape every suggestion, review, spec, and PR this framework
produces — judgment defaults, not a checklist, applied where they change a
decision:

- **Zero-trust by default.** Flag anything resembling a VPN-style "trusted
  network" assumption — that model is exactly what Neeve replaces for
  customers.
- **Simplify, don't accrete.** Hold code to the same standard as the product
  pitch.
- **State the operational stakes, every time.** Name the business/
  operational consequence alongside the technical one — never leave it
  implied. The full discipline (production consequence + a Gaps list, never
  a silence) is `context/fragments/production-consequence-and-gaps.md`;
  every skill and the unified agent are held to it.

## Where the Deeper Reasoning Lives

- `engineering-principles.md` — the Product/Design/Engineering charter,
  each principle traced to a named industry practice (Layer 03).
- `references/pm-lens.md`, `references/design-review.md`,
  `references/security.md` — specialist checklists derived from that charter.
- `products/robin/product-overview.md` — Robin-specific repo table and
  local-dev instructions (product-specific detail, not company-wide).
