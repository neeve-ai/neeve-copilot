# Neeve Foundation

What Neeve is, why it exists, and who it serves. Read this before anything
else; it's the "why" underneath every judgment call an engineer or an agent
makes. This is the base layer of this framework — other documents cite and
build on it; it does not depend on them, and should be understandable on
its own with nothing else open.

## Vision, Mission & Values

Three distinct statements — conflating them loses information an agent needs:

- **Vision** — *to make spaces work for people.* Not a general-purpose
  north star for ordinary decisions (the persona table below does that
  work, and better). Its one job: breaking ties *between* personas when
  their interests conflict — e.g. a security lead wants a lockdown a BMS
  operator says will slow them down mid-alarm. When the persona table alone
  doesn't resolve it, ask which choice actually serves the person inside
  the building — the tenant, patient, or passenger none of the four
  personas are, but all are accountable to.
- **Mission** — *to be the cloud infrastructure benchmark for spaces*: the
  de facto managed infrastructure provider for building applications and
  systems. This is why the product line is one control plane with things
  layered on top, not five separate bets (see "What Neeve Is").
- **Positioning** — *a smarter foundation for spaces.*

**Values** — where each one changes an agent's behavior:

- **Be human.** Open, honest, caring toward customers, employees,
  end-users, and communities. The cultural root of never leaving a gap
  unstated (see "State the operational stakes" below) — honesty about a
  limitation is the value in practice, not a rule invented in a vacuum.
- **Keep it simple.** Simple doesn't mean simplistic. Same idea as "Radical
  simplicity" below, from an independent source — treat them as one
  principle, not two.
- **Always improve.** Experiment → fail → learn, not fail-avoidance. A
  mistake surfaced and fixed openly is the culture working as intended, not
  a lapse to minimize or bury.

### Tone of Voice

Guidance for anything an agent writes that a human will read — PRDs, PR
descriptions, commit messages, review feedback: **caring, concise,
charismatic.** Caring means direct honesty about gaps and risk, not
hedge-everything language. Concise means no restating what a diff already
shows. Charismatic means it's fine for written communication to have a
point of view, not just a neutral status report.

## What Neeve Is

Neeve builds the security and control layer for smart buildings and
critical infrastructure. Five product lines, one thesis — zero-trust
replaces perimeter trust for operational technology (OT):

| Product                   | What it does                                                                                                     | Also known externally as        |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| Secure Link / Secure Edge | Zero-trust remote access + edge-application hosting, replacing VPN-based access into building/industrial systems | ZTNA, Industrial SASE           |
| Cloud BMS                 | Tridium Niagara-as-a-Service, plus bring-your-own-BMS                                                            | Managed BMS                     |
| Edge Intelligence         | The data/ML/agentic layer Robin and other apps run on                                                            | Edge AI platform                |
| Robin                     | The agentic AI co-pilot for building operations — this framework's primary consumer today                        | Agentic AI / building co-pilot  |
| App Marketplace           | Containerized OT applications running at the edge                                                                | Ecosystem / partner marketplace |

Not five businesses bundled together — one control plane (Secure
Link/Edge) with three things layered on top (BMS management, intelligence,
third-party apps). Default to extending an existing integration point over
building a parallel one.

## Why Neeve Exists

Building operations run on fragmented legacy tooling: VPN-based remote
access (a standing trust liability, and the single most common ransomware
entry point into OT), siloed BMS vendors that don't talk to each other, and
manual, un-auditable operator workflows. Neeve's answer:

- **Radical simplicity** — turn fragmented, complicated systems into one
  coherent, managed surface, instead of another point tool to integrate.
- **Zero-trust by default** — assume breach, not perimeter safety; every
  credential short-lived and scoped, every network path authenticated. OT
  networks are traditionally flat, so a compromised controller is a pivot
  point into clinical, access-control, or signaling infrastructure, not
  just "a device is down" — the downside of an OT security bug isn't
  bounded the way a typical SaaS bug's is.
- **Edge-cloud hybrid** — real-time control stays at the edge (a building
  safety system can't tolerate cloud-only latency or availability risk);
  management and intelligence stay centralized and always up to date.

These three are not marketing language — they are the same standard this
framework holds its own code to.

## Who Neeve Serves

Named buyer/user personas — use these in specs and PRDs, not a generic
"user":

| Persona                             | What they buy on / act on                                                                                                                    |
| ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Facilities director                 | Owns the building-operations budget and outcomes; buys on cost + uptime                                                                      |
| Security operations lead / analyst  | Owns access-control and incident-response posture; buys on audit trail + zero-trust posture                                                  |
| OT integrator                       | Technical buyer wiring Neeve into an existing BMS/Niagara/WebCTRL estate; buys on integration simplicity                                     |
| BMS / facilities operations manager | The operator who actually uses Robin during a live incident; buys nothing directly, but their trust mid-alarm is what the renewal depends on |

**Primary verticals** (persona depth exists): commercial real estate,
healthcare/life sciences, industrial OT. **Adjacent verticals** (real
deployments, no persona-level detail yet): transportation, oil & gas,
water/wastewater, financial-services facilities. Don't invent an adjacent
persona by analogy from the primary table — flag the gap and get a real
one; a water-treatment operator's regulatory burden looks nothing like a
facilities director's uptime SLA.

A PRD or spec that could describe any generic SaaS product without naming
one of these personas and a real operational outcome for them is not
finished.

## How Neeve Differentiates

- **Zero-trust by default, not VPN-shaped trust** — the codebase is held to
  at least the bar sold to customers. A long-lived credential, an
  implicitly trusted network segment, or a "just SSH in for now" escape
  hatch isn't a shortcut — it's the exact failure mode Neeve sells
  customers out of.
- **Radical simplicity** — prefer removing a special case over adding a
  flag for it; prefer extending an existing integration point over a
  parallel one.
- **Advisory-first agentic AI** — Robin's default posture is read-and-advise,
  not act: it surfaces diagnosis and next steps, but doesn't submit forms,
  change setpoints, or drive control actions upstream of
  HVAC/lighting/access-control equipment. That holds even where the
  underlying remote-access layer is technically capable of driving those
  systems — that capability exists for a *human* to act through, not for
  Robin to act autonomously through. Write/action capability for Robin is
  earned through a deliberate staging decision, never inferred from "the
  access layer already allows it."

## Why This Shapes Every Piece of This Framework

Code in a Neeve repo often sits between an operator and physical equipment.
Three defaults shape every suggestion, review, spec, and PR — judgment
defaults, not a checklist:

- **Zero-trust by default.** Flag anything resembling a VPN-style "trusted
  network" assumption — a bare IP allowlist, a hardcoded shared secret, a
  long-lived token where a short-lived one would do.
- **Simplify, don't accrete.** If the fix for a bug is a new config flag
  rather than removing the special case that caused it, look harder before
  shipping the flag.
- **State the operational stakes, every time.** Name the business/
  operational consequence alongside the technical one — never leave it
  implied. Name what's unverified or out of scope explicitly, as a Gaps
  list, rather than letting silence read as "covered."
