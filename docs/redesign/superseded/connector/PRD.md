# PRD: Neeve Context Connector

> [!WARNING]
> **WITHDRAWN — 2026-09-02. This describes a service that will not be built.**
>
> The `neeve-context` MCP server was justified almost entirely by supporting a browser-only
> population on claude.ai. With that surface out of scope and every population holding a git
> clone, its read plane collapses into a file read and its write plane into a pre-commit
> linter. See decision **D7** in [`../../ARCHITECTURE.md`](../../ARCHITECTURE.md) §15 for the
> scorecard and the trigger condition that would reopen this.
>
> Retained so the reasoning stays findable rather than being rebuilt from scratch.

---

**Feature slug:** `neeve-context-connector`
**Status:** draft → reviewed → approved → in-design → in-erd → in-spec → in-implementation → shipped
_(current: **draft**)_
**Prototype expected:** no → straight to `to-erd`. There is no end-user UI; the surfaces are
Claude's own (tool calls, connector settings). A DLS prototype would have nothing to draw.

---

## Template deviations — declared, not silent

`to-prd` Core Rule 2 requires Section 2 to name a security-operations or
facilities-operations persona in a commercial-real-estate OT context, and to refuse
finalization if the section could describe any SaaS product.

**This feature is internal tooling, and that rule does not literally apply.** Rather than
fabricate a building-security persona to satisfy the template, Section 2 names the real
primary persona (an internal Product Manager) and Section 2a states the connection to the
CRE-OT mission honestly. Flagging this as a deviation is the intended handling under
`to-prd` Core Rule 5 (state gaps explicitly) rather than a template violation to hide.

`to-prd` Phase 4 requires the PRD to be committed into the planning repo as system of
record. **This document is at `PRD.md`, which is not a system-of-record
location.** That is a real gap, listed in Section 9. It is also the exact problem this
feature exists to solve, which is either fitting or embarrassing depending on your mood.

---

## Change & Decision Log

Append-only. Every later phase that changes scope, a requirement, an assumption, or a
decision adds a row in the same commit as the change. Never edit or delete a prior row.

| Date | Phase | Author | Change | Why | Commit/PR |
|------|-------|--------|--------|-----|-----------|
| 2026-08-27 | PRD | @dhruva | Initial PRD | PMs are moving to claude.ai org-provisioned skills; research established that a connector is the only artifact that serves both surfaces, is the only grounding channel for browser users, and the only path to binding enforcement there | `pending` |
| 2026-08-28 | PRD | @dhruva | **Scope reduction.** Layers 03/04 served exclusively by NotebookLM as a peer; retired FR-4 and FR-5 | Layers 03/04 are a static reference corpus, not a records system. One exclusive home applies "one fact, one place"; a mirror would manufacture two authoritative systems | `pending` |
| 2026-08-28 | PRD | @dhruva | **Reversal — supersedes the row above.** Layers 04 and 03a move into git (`foundation/`, `process/narrative/`) and are served by this connector. FR-4 and FR-5 reinstated. NotebookLM demoted to a derived, non-authoritative projection. See ARCHITECTURE ADR-11 | The prior decision conflated **consumption** with **authoring**: Layer 04 is read by many but written by few, rarely — so the non-engineer-audience argument applies to reading, which serving over MCP solves. Bundling in git restores change history (the largest accepted cost of the prior row), collapses the ADR-10 narrative/rules seam into a single reviewable diff, removes a failure mode that could not be read server-side at all under interactive auth, and shrinks three peers to two — which lowers the programme's single largest risk, discoverability | `pending` |

---

## 1. Problem & Opportunity

Neeve's agentic framework today assumes every user has a filesystem, a git checkout, and a
terminal. All of its grounding (the per-repo `.help/` book), all of its always-on context
(a 469-line block merged into `~/.claude/CLAUDE.md`), and all of its enforcement
(pre-commit hooks, CI) rest on those three assumptions.

Product Managers have none of them. They work in claude.ai in a browser.

Three consequences follow, and all three are live today:

1. **A PM has no grounding at all.** They cannot read a repo's book, cannot check whether a
   capability already exists, cannot see the repo topology. They are running a
   general-purpose assistant with no knowledge of Neeve, which is precisely the failure the
   framework was built to prevent.
2. **A PM's process rules are unenforceable.** Research confirmed that organization
   instructions on claude.ai are advisory, not binding, and tool-approval prompts add
   friction without blocking. So "a PRD names a persona and a measurable outcome" is a wish
   for browser users, no matter how firmly it is written down.
3. **Engineers' grounding is single-repo, and a PM's question never is.** "Does this exist
   already?" spans ~16 repos. `repo-intel` scans one. Nobody can answer the cross-repo
   question cheaply, on either surface.

**Why now.** Three things changed at once. Organization-provisioned skills became available
on claude.ai (Team/Enterprise), making a real PM rollout possible for the first time.
Remote MCP connectors became org-deployable with pre-authorized auth, removing the per-user
OAuth burden that would previously have killed adoption. And the framework's own
always-on payload has grown to 469 lines — of which ~30% is engineering-only and ~18% is
one product's infrastructure runbook — which makes "just push more context at everyone"
visibly the wrong answer rather than merely an inelegant one.

**The opportunity.** One service closes all three gaps with one mechanism, and it is the
only artifact in the design that serves both surfaces at once.

---

## 2. Primary Journey: Product Manager drafting from a vague idea

**Persona.** A Neeve Product Manager. Browser only — claude.ai, no terminal, no git
checkout, no local development environment, and no realistic path to acquiring one.

**The operational outcome they need.** To go from a vague idea to a PRD that is grounded in
what Neeve already has, in one sitting, without needing an engineer to answer "does this
exist already?" and without producing a document that a security review or an engineering
team will send straight back.

**What they do today.** They open claude.ai and describe the idea. Claude, having no Neeve
context, produces a well-structured PRD containing invented personas, plausible-sounding
capabilities Neeve does not have, and no awareness that two of the four things being
proposed already ship. The PM either spends a day in Slack reconstructing reality from
colleagues, or forwards the document and lets an engineer discover the problems during
ERD breakdown. Both paths burn the time the tool was supposed to save, and the second
path burns an engineer's time too.

**The journey with this feature.**

1. The PM describes the idea. The `to-prd` skill — delivered through the organization
   library — triggers on the phrasing.
2. Before drafting, the skill queries the connector: has this been proposed before
   (`prd_search`), which repos and products does it touch (`repo_registry`), does the
   capability partly exist already (`book_search` across the whole book corpus), who is the
   relevant persona (`org_facts`), and what does our process require at this stage
   (`process_narrative`). **One place to ask** — which is the practical payoff of ADR-11 and
   the reason the ambient block's routing job is now tractable in ~40 lines.
3. The PM gets told, with citations, that two-thirds of this exists and the real gap is
   narrower than they thought. **This is the moment of value** — it happens before a word
   of the PRD is written, and it is impossible today.
4. Stage 0 binds the artifact: the connector resolves where this org keeps PRDs and returns
   the target location.
5. `create_prd` writes it — and **refuses** if there is no named persona or no measurable
   outcome. Not a warning in the output that a busy reader skims past; a rejection with a
   specific, actionable reason.
6. The write is logged with actor, timestamp, and content delta, because no audit trail
   exists on the Anthropic side for commercial claude.ai.

### 2a. How this serves the CRE-OT mission

Indirectly, and it is worth being honest that it is indirect. Robin's actions reach real
building equipment; the framework exists because an agent editing that code from a stale
map is dangerous. A PRD built on invented capabilities propagates that wrongness downstream
into every work item `to-erd` derives from it, and from there into specs and code that
touch equipment. Grounding the top of the Design Loop is the cheapest place to stop a
wrong assumption, because it is the only place where stopping it costs one conversation
instead of one release.

---

## 3. Secondary Personas & Journeys

Explicitly secondary to Section 2.

**Engineer on Claude Code.** Gains the cross-repo question they cannot answer today: "which
repos does this contract touch?", "has this decision been made before?". Their single-repo
grounding via the local `.help/` book is unchanged and remains primary — the connector is
additive for them, never a replacement. Notably, engineers **degrade gracefully** if the
connector is down; PMs do not (Section 9).

**Designer.** Reads personas, product context, and prior decisions. Lower volume, same read
path, no write path in v1.

**Framework maintainer.** Gains the answer to "what do our PMs actually have?" — which the
org-provisioned-skills console cannot answer, since it offers no versioning or audit.

**Explicitly not a persona in v1:** external partners, customers, and anyone outside the
Neeve directory. The connector serves internal knowledge and has no tenancy model.

---

## 4. Success Metrics

**Adoption**
- ≥ 80% of PMs in the pilot group make at least one connector query per active week by
  week 4. Below that, the discoverability risk (Section 11) has materialised.
- ≥ 90% of new PRDs created through `create_prd` rather than pasted into Confluence by
  hand, measured from month 2.

**Operational**
- Median PM time from idea to grounded first PRD draft: baseline to be measured in pilot
  week 1, target 50% reduction. *Stated honestly: this baseline does not exist yet, so the
  target is provisional until it does.*
- Engineer-hours spent correcting PRD factual errors during `to-erd`: target 75% reduction.
- PRDs citing a repo or capability that does not exist: **target zero.** This is the
  metric that most directly represents the problem, and it is currently unmeasured.

**Process integrity — the north-star metric**
- Share of PM-facing process rules at `Blocked` or `Surfaced` tier rather than `Advised`.
  Today: **0% for browser users**, because no binding mechanism exists there. Target after
  Phase B: every rule in the `create_prd` contract at `Blocked`.
- Ambient always-on block: 469 lines → ≤ 40 for Claude Code users, and the concept retired
  entirely for web users, where it was never available to administer anyway.

**Leading indicator of gate quality, not just gate presence**
- First-attempt `create_prd` rejection rate. Expected to start high and fall. If it stays
  high, the gate is teaching nothing and the error messages are the defect. If it is near
  zero from day one, the gate is too weak to be worth its cost. Either extreme is a signal
  to act on.

---

## 5. Scope

**In scope**

- A remote MCP server, `neeve-context`, deployed on Neeve infrastructure.
- Read capabilities: `repo_registry`, `book_search`, `book_fetch`, `prd_search`,
  `org_facts` (Layer 04), `process_narrative` (Layer 03a) — all **QUERY-channel**, never
  rendered into ambient context.
- Write capabilities with deterministic validation: `create_prd`, `create_work_items`,
  `record_decision`, `record_lesson`.
- Ingestion of the `.help/` book corpus from product repos, pull-based on an interval.
- An append-only audit log of every write, since Anthropic provides none for commercial
  claude.ai.
- Org-wide deployment scoped to a SCIM directory group, with pre-authorized auth so no PM
  performs an OAuth dance.
- Substrate adapters for the planning workspace: git planning repo and Confluence/Jira.

**Out of scope**

- **Rendering Layers 04/03a into the always-on ambient block.** They are stored in git and
  **served on query** (ADR-11). Storage location and delivery channel are independent
  decisions; conflating them reinvents the 469-line payload with extra steps. This is the
  most likely way for the ADR-11 reversal to go wrong later.
- **Serving Layer 03b as a tool.** Gate commands, validation predicates, and acceptance
  contracts stay in git and are read *directly* by CI and by this service's validators —
  never round-tripped through MCP, because a gate must read its rulebook with no human
  present to authenticate.
- Any authoritative role for NotebookLM. It is a derived projection, regenerated from git.
- Any UI of our own. Claude is the client; the connector has no front end.
- Becoming a source of truth. The connector aggregates and serves facts owned elsewhere;
  if it ever becomes the only place a fact lives, "one fact, one place" is dead and this
  PRD has failed.
- Model calls inside the server. Validation is mechanical, always — a validator that
  reasons can be reasoned with.
- Serving anything to non-Neeve identities. No multi-tenancy, no partner access.
- Replacing the Atlassian, AWS, or other existing connectors. Live external state stays
  theirs to serve.
- Write access for the design discipline in v1.
- Real-time push or resource subscriptions — not supported by the platform, and not needed.

---

## 6. Functional Requirements

Numbered for `to-erd` to break down; the engineering-level FRs live in `DESIGN-SPEC.md`.

- **FR-1.** Serve a repo registry: every product repo with purpose, ownership, and product
  mapping. This replaces the ~84-line topology table currently pushed into every user's
  always-on context.
- **FR-2.** Serve the aggregated `.help/` book corpus with search and section-fetch.
  Search-then-fetch, never bulk return — the platform caps tool results at ~150,000
  characters.
- **FR-3.** Serve a searchable corpus of existing PRDs and ADRs, so "has this been proposed
  before" is answerable before drafting.
- **FR-4.** Serve Layer 04 org facts — personas, customers, conventions — from
  `neeve-copilot/foundation/`, on demand. *(Retired then reinstated same day; see the
  Decision Log and ADR-11.)*
- **FR-5.** Serve Layer 03a process narrative — stage rationale, what good looks like — from
  `neeve-copilot/process/narrative/`, on demand. The Layer 03b **executable rules** remain
  unserved by design: CI and validators read them straight from git, because a validator that
  fetches its rulebook over an authenticated network call is not a validator.
- **FR-6.** `create_prd` validates deterministically and **rejects** on failure: named
  persona, measurable outcome, workspace bound. Rejections state precisely what is missing.
- **FR-7.** `create_work_items` validates dependency ordering and repo grounding.
- **FR-8.** `record_decision` and `record_lesson` capture ADRs and corrections.
  `record_lesson` is the only place a correction can land for a browser user, and is
  therefore the sole web path for the framework's feedback loop.
- **FR-9.** Resolve caller identity and directory-group membership on every call; deny by
  default when identity or group cannot be resolved.
- **FR-10.** Write an append-only audit record for every write: actor, timestamp,
  parameters, and content delta.
- **FR-11.** Ingest books from product repos by **pulling** from git on an interval —
  requiring no change to, and committing nothing into, any product repo.
- **FR-12.** Enforce the result-size cap server-side, with explicit truncation and a
  continuation token rather than a silently clipped response.

---

## 7. Enterprise Requirements (Launch Blockers, Not Deferred)

| Requirement | Status | Detail |
|---|---|---|
| **SSO / SAML** | **In scope now** | Enterprise Managed Auth, so PMs connect silently via a signed IdP assertion with no consent screen. Static-header auth is the documented alternative but is beta and shares one org-wide credential — acceptable only for the read-only pilot, never for the write plane. |
| **RBAC** | **In scope now** | Authorization on SCIM directory group. Read scoped by group; write tools scoped per artifact type. Deny by default. |
| **Audit logging** | **In scope now, and unusually load-bearing** | Commercial claude.ai has no org-level artifact audit log; the Compliance API is Claude-for-Government only and excludes content by design. If we do not build this, PRD-as-system-of-record has **no audit trail whatsoever** on the web surface. |
| **Data residency** | **In scope now** | The book index contains proprietary code structure. Index and audit store are hosted in Neeve-controlled infrastructure in a named region. No artifact content is sent anywhere beyond the model provider inherently in the conversation. |
| **Bypass closure** | **In scope now — and easy to miss** | A `Blocked` gate in `create_prd` only holds if the raw Confluence/Jira write path is set to `blocked` at the connector permission level for the PM group. Otherwise the PM can write directly and the gate is decorative. This is a launch blocker, not a hardening step. |

---

## 8. Security & Compliance Considerations

**Frameworks.** SOC 2 Trust Service Criteria apply directly: access control (FR-9), audit
logging (FR-10), change management for the ingestion pipeline. NIST CSF Identify and
Protect apply to the book corpus as an asset inventory. **IEC 62443 does not apply** — the
connector touches no OT zone or conduit, has no network path to building equipment, and
never will. Stated explicitly rather than omitted.

**Data classification.** The book corpus is Neeve-internal proprietary: architecture,
guarded surfaces, deployment topology. The PRD corpus may contain unreleased roadmap and
customer-identifying context. Neither is public. Both are more sensitive in aggregate than
individually, which is exactly what this service creates — an aggregate.

**Zero-trust framing — three new trust boundaries, and this is the section to read twice.**

1. **Claude → connector.** A new internet-reachable authenticated surface. Mitigation:
   HTTPS only, EMA/OAuth with PKCE, deny-by-default authz, per-identity rate limiting.
2. **Connector → git and Confluence/Jira.** New long-lived credentials. Mitigation: git
   access is a **read-only** deploy credential; the write credential is a service account
   scoped to the planning space alone, never org-wide admin.
3. **Book and PRD content → model context.** This is the non-obvious one. **Content served
   by this connector is untrusted input flowing into a model's context.** A compromised or
   merely careless `.help/` book could carry instruction-shaped text that a model treats as
   direction. The connector is a prompt-injection vector by construction, and the current
   design has no defence beyond serving content with provenance labels and never as
   instructions. Named as a gap in Section 9 rather than claimed as solved.

**Aggregation risk.** One credential compromise exposes the entire internal knowledge
corpus in one query-able place, where previously an attacker needed access to sixteen
separate repositories. The convenience that makes this feature valuable is the same
property that makes it worth attacking.

---

## 9. Operational Consequence & Gaps

**What breaks if this is wrong.**

| Failure | Who notices | Blast radius |
|---|---|---|
| Connector unavailable | **Every PM, immediately and totally** | All browser users lose all grounding at once. Engineers degrade gracefully — local books and git still work. **The degradation is asymmetric and PMs get the bad half.** |
| Stale book index | Nobody, until a PRD is wrong | Silent. Worst failure mode in the system: confident answers from an outdated map, which is the exact thing the framework exists to prevent. Mitigation: serve index age with every result and refuse to answer beyond a staleness threshold. |
| Validator too strict | PMs, loudly | Work stops or the gate gets disabled in annoyance. A disabled gate is worse than a weak one. |
| Validator too lax | Engineers, later | Ungrounded PRDs flow downstream as before; the feature's central promise quietly fails. |
| Audit log gap | An auditor, at the worst possible time | No record of who created or changed what. Unrecoverable retroactively. |
| Credential compromise | Security, eventually | Entire internal knowledge corpus in one place (Section 8). |

**Rollback / kill-switch.** Three levels, fastest first: set individual tools to `blocked`
in connector settings (seconds, no deploy); disable the connector for the group (seconds);
remove it org-wide (seconds). PMs fall back to writing in Confluence by hand — degraded but
not blocked. The write plane can be disabled independently of the read plane, which is why
they are separate rollout phases.

**Gaps — named, not silent.**

1. **Prompt injection through served content has no mitigation designed.** Provenance
   labelling is stated as an intent, not a control. This needs a real answer before the
   corpus includes anything a third party can influence.
2. ~~**This PRD is not in a system-of-record location.**~~ Moot as of 2026-09-02: the whole
   feature was withdrawn (see the banner at the top of this file), so there is no live
   artifact for this PRD to be the system of record *for*. It is retained as a record of a
   decision not taken.
3. **No availability owner.** §8.6 of the redesign proposal flagged this and it is still
   open: the framework becomes a service with an uptime expectation, and nobody has agreed
   to carry the pager. **This is the largest non-technical gap and it blocks Phase B, not
   Phase A.**
4. **The time-to-first-PRD baseline does not exist**, so that success metric is provisional.
5. **Discoverability is unproven.** The entire design assumes the model will *ask* the
   connector rather than answer from its own priors. Untested. Phase A exists largely to
   test it.
6. **MCP prompt UX on claude.ai is undocumented.** Platform support is confirmed; how
   prompts surface to a user is not. Affects whether prompt templates are a usable PM
   affordance.
7. **CI cannot call this connector** — interactively-authenticated servers are absent in
   headless runs. So engineer-side `Blocked` gates stay git/CI-local. A service-account
   path is possible but unscoped.
8. ~~No change history for Layers 03/04.~~ **Closed by ADR-11** — git restores diff, blame,
   review, and the existing CI citation checks. This was the largest accepted cost of the
   superseded design and reversing it was the main reason for the reversal.
9. **Concentration risk, newly enlarged.** A connector outage now costs PMs Layers 04 and 03a
   as well as 02. Consolidating three peers into two bought better routing at the price of a
   wider single point of failure. **This raises the stakes on gap 3 (no availability owner)
   rather than adding a separate gap.**
10. **Federated discovery still has no single entry point, but a narrower gap.** Prior-art
    questions now span two systems — the connector and Confluence — rather than three. A
    silently missing source still reads as *"no prior art exists,"* which remains the worst
    wrong answer this class of question can give, so per-source status labelling is still
    required.
11. **Layer 04 authoring by non-engineers is unresolved but tractable.** A PR through
    GitHub's web UI is browser-based and adequate at quarterly cadence. A
    `propose_foundation_change` write tool that opens a PR would be more elegant and is
    deliberately out of scope.
12. **Depth check:** claims about connector auth modes, transport, result-size and timeout
   limits, org-provisioned skills, and the absence of a commercial audit API were grounded
   in current vendor documentation during research rather than recalled. **Not** grounded:
   whether the admin surfaces cited from government-tier documentation are identical for
   commercial Team/Enterprise, and whether a browser-based Claude Code surface exists that
   would change the two-channel premise. Both are listed as open questions.

---

## 10. Staged Rollout & Rollback

**Phase A — read-only pilot.** Read tools only, 2–3 volunteer PMs, one directory group.
Static-header auth acceptable here. Exit criteria: the discoverability question is answered
with real numbers; index staleness is observed rather than assumed; no PM reports a
confidently wrong answer traceable to the corpus.

**Phase B — write plane, limited GA.** `create_prd` first, at `ask every use`. Requires
gaps 1 and 3 closed and EMA in place. Exit criteria: first-attempt rejection rate trending
down; audit log verified complete against a manual reconciliation; the raw Confluence write
path confirmed `blocked` for the PM group.

**Phase C — full GA plus feedback loop.** Remaining write tools, `record_lesson`
aggregation, engineers onboarded for cross-repo reads.

**Can it be turned off for one group without turning it off for all?** Yes — connector
configuration is per directory group, and tool permissions are per tool. A misbehaving
validator can be disabled for one group while the read plane stays up for everyone.

---

## 11. Dependencies & Risks

| Dependency | Type | Note |
|---|---|---|
| claude.ai org connector admin surface | Authoritative | Verify commercial-tier parity with the cited documentation before rollout |
| Enterprise Managed Auth / IdP | Authoritative | Requires Team or Enterprise plan and IdP issuer configuration |
| SCIM directory sync | Authoritative | Group scoping depends entirely on it; no SCIM means no PM-only scoping |
| Product repos' `.help/` books | Derived | Corpus quality is capped by book quality. Books are currently uneven, and TS/Go symbol detection is admittedly conservative |
| Planning workspace (git or Confluence) | Authoritative | Substrate choice per §7 of the redesign proposal |
| Atlassian connector | Transport-only | Adopted for live state; must be `blocked` for governed writes to close the bypass |
| `neeve-copilot` repo (`foundation/`, `process/`, `registry/`) | **Authoritative** | Layers 04, 03a, 03b and the registry config. Ingested read-only, same as the books. Its content quality caps the answers |
| NotebookLM | **Derived** | A regenerated projection for exploratory synthesis. Non-authoritative; its absence has no functional impact (ADR-11) |

**Risks, highest first.**

1. **Discoverability failure.** If the model answers from priors instead of querying, the
   entire investment returns nothing. Cheapest possible test, run first in Phase A.
2. **Nobody owns the service.** Gap 3. A framework becoming a service without an on-call
   owner fails operationally regardless of design quality.
3. **Corpus quality caps everything.** A connector serving mediocre books mostly serves
   mediocre answers faster.
4. **Prompt injection.** Gap 1. Currently undefended.
5. **Manual org-skill publishing.** No Admin API, so the PM-facing skill set is uploaded by
   hand with no versioning. Mitigation is a committed manifest with checksums; the risk of
   drift between repo and console remains real.
6. **Aggregation makes a better target.** Section 8.

---

## 12. Open Questions

1. Does a browser-based Claude Code surface exist? If so, PMs could get the full plugin
   system — versioning, group scoping, CI publishing — and most of the two-channel problem
   collapses. **This should be resolved before Phase B, because it could change the
   architecture.**
2. Are the commercial Team/Enterprise admin surfaces identical to the government-tier
   documentation the research cited?
3. Who carries the pager (gap 3)?
4. Does compressing skill descriptions to the 200-character web cap degrade auto-invocation
   accuracy? Affects whether PM skills reliably trigger at all.
5. Should the connector serve the process definition as MCP *resources* or *tools*? Depends
   on the undocumented prompt/resource UX.
6. **A Layer 02 question, not Layer 04:** git planning repo or Confluence as the default PM substrate? Git gives real `Blocked`
   enforcement via CI; Confluence is where PMs already are. A browser PM cannot commit to
   git without the connector doing it on their behalf — which is possible, and would be the
   best of both, but adds a write path we have not specced.

---

## 13. PM Review

`neeve/references/pm-lens.md`'s 5-point checklist, applied to this draft.

| # | Item | Verdict | Justification |
|---|---|---|---|
| 1 | Named outcome, not internal capability | ✅ | Named persona (browser-only Neeve PM) and named outcome (grounded PRD in one sitting, no engineer round-trip). Deliberately not framed as "build an MCP server." |
| 2 | Enterprise requirements checked now, not deferred | ✅ | Section 7: SSO/EMA, RBAC, audit logging, and data residency all in-scope-now. Audit logging is a genuine launch blocker here because no vendor-side equivalent exists. Bypass closure added as a fifth requirement. |
| 3 | Staged rollout and rollback story | ✅ | Section 10: three phases with exit criteria; three kill-switch levels; per-group and per-tool disable both confirmed. |
| 4 | Scope discipline | ✅ | **Resolved 2026-08-28.** The earlier ⚠️ flagged FR-5 (serve the process definition) as the least load-bearing item. It is now retired outright, along with FR-4, by the Layer 03/04 decision — the scope shrank rather than being deferred, which is the better outcome. Nothing remaining answers a question nobody asked. |
| 5 | Business/operational stakes and gaps stated | ✅ | Section 9 names asymmetric degradation (PMs lose everything, engineers degrade gracefully), the silent-staleness failure as the worst mode, and eight explicit gaps including two — no service owner, undefended prompt injection — that gate Phase B. |

**Note for the reviewer:** all five items are now ✅. That is not a claim of completeness —
gaps 1 and 3 in Section 9 remain Phase-B blockers, and gaps 8 and 9 (no change history for
Layers 03/04; no single entry point for federated discovery) are new accepted costs of the
2026-08-28 scope decision rather than problems solved by it.

---

**Handoff:** feature-slug `neeve-context-connector` → `to-erd` directly (no prototype).
Architecture lock: `ARCHITECTURE.md`. Engineering spec:
`DESIGN-SPEC.md`.
