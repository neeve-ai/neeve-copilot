# neeve-copilot/neeve/org — source for `neeve-ai/.github-private`

Enterprise-level custom-agent governance for GitHub Copilot, per
[Preparing to use custom agents in your enterprise](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-agents/prepare-for-custom-agents).

**This folder is committed source inside `neeve-copilot`, not the live
governance repo itself.** GitHub only recognizes org-wide custom agents from
a repo literally named `.github-private` sitting at the org root — a
subfolder of `neeve-copilot` can never satisfy that, no matter what it's
named. So the content lives here for editing/versioning alongside everything
else in `neeve-copilot`, and gets **exported** (copied) to a real, separate
`neeve-ai/.github-private` repo when the org is ready to go live — see
"Setup required on GitHub" below. Until that export happens, nothing here is
active; this is the same source/output split `neeve-copilot` already uses
for skills, prompts, and per-repo instructions.

## Why this exists alongside the rest of `neeve-copilot`

`neeve-copilot` proper (skills, prompts, per-repo instructions, hooks) stays
the primary mechanism — it's cross-agent (Claude Code, Cursor, Codex,
Copilot) and per-repo. This folder covers the one thing that mechanism can't:
**always-available, org-wide custom agents that work even in a repo with zero
local Copilot setup**, plus enterprise audit-log visibility into agent
sessions (`actor_is_agent`, session activity) — relevant given Neeve's
OT/critical-infrastructure customer base and eventual compliance asks
(SOC2 etc.).

Five agents are drafted here, one per discipline plus the domain specialist.
`PRINCIPLES.md` is the charter they're condensed from — read it first if you
want the *why*, not just the *what*, behind any agent's behavior. Each
principle in that charter is adapted from a named practice at a company
strong on that dimension (Amazon, Okta, Google SRE, Stripe/Linear,
Anthropic/OpenAI, Vanta/Wiz, Palantir — see the charter for which lineage
maps to which principle), flavored for Neeve's actual offering and customer
base rather than applied generically.

| Agent | Discipline | Purpose | Status |
|---|---|---|---|
| `neeve-reviewer` | Engineering | Ad hoc Neeve-flavored code/spec review (culture/ethos + spec-review/code-review rubrics) for any repo, including ones that haven't adopted the `neeve-copilot` skill pipeline yet | staged, ready to test |
| `neeve-security-partner` | Security | Dedicated adversarial security pass — OWASP coverage, pentest-mindset actor simulation, security-gate completeness, enterprise multi-tenancy properties. Separate from `neeve-reviewer` because Neeve sells zero-trust security as the product and the codebase should be held to at least that bar | staged, ready to test |
| `neeve-pm-partner` | Product | PM-shaped questions before/alongside `to-spec`: named customer outcome, enterprise requirements (SSO/RBAC/audit/data residency) as launch blockers not phase-2, staged-rollout/rollback story, scope discipline | staged, ready to test |
| `neeve-design-partner` | Design | DLS pixel-perfect fidelity, WCAG 2.1 AA accessibility as a launch blocker, failure-state-first design for live building data | staged, ready to test |
| `neeve-ot-specialist` | Domain (OT) | OT/building-automation-aware agent (Niagara/BQL/WebCTRL) | placeholder — gated on the `ot-building-automation` skill getting SME review (see `neeve-copilot`'s `agents-src/README.md` and the skill's own `[needs SME review]`-flagged content) |

## Setup required on GitHub (not done yet)

1. Create `neeve-ai/.github-private` as an **Internal or Private** repo in the
   `neeve-ai` GitHub org (must be `.github-private`, not `.github`, for
   Enterprise — confirm this org sits under a GitHub Enterprise account first).
   This is a brand-new, separate repo — it is not `neeve-copilot` and does not
   contain `neeve-copilot`'s history.
2. Enterprise owner enables the org/enterprise setting that allows custom
   agents to be created and consumed from this repo (ruleset-gated — an
   enterprise owner needs to confirm/enable this; contact them before
   assuming it's on).
3. Copy this folder's `.github/agents/` (staging) content — plus
   `PRINCIPLES.md` for reference — into that new repo's own `.github/agents/`.
   This is a one-time export, not a git operation on `neeve-copilot`; the new
   repo starts its own history.
4. Test each agent by starting a task from within the new `.github-private`
   repo itself (per GitHub's docs, staged agents only work when a session is
   started *inside* the repo that stages them).
5. **Promote to org-wide**: in the new repo, move a validated agent's file
   from `.github/agents/<name>.agent.md` to `agents/<name>.agent.md` at repo
   root, merge to the default branch. It is then available to all
   org/enterprise members with access to that repo, in any repo they work in.
6. Confirm who can view/manage this via the enterprise "AI manager" role
   (audit logs, session visibility) if/when that becomes a compliance need.
7. Once the export is live, treat the real `neeve-ai/.github-private` repo as
   the place agents get *tested and promoted*; keep editing the *content* here
   in `neeve-copilot/neeve/org/` and re-export on change, the same direction
   skills/prompts/instructions already flow (source here → output elsewhere).

## Keeping content in sync with the rest of `neeve-copilot` and `PRINCIPLES.md`

These `.agent.md` files intentionally restate a condensed version of both:
- the culture/ethos section and review rubrics that live canonically in
  `neeve-copilot/neeve/products/robin/context-src/base.md` and `fragments/`
- the expanded reasoning in `PRINCIPLES.md` (this folder), which is the
  source of truth for *why* — edit `PRINCIPLES.md` first when a principle
  changes, then update the affected agent(s) to match.

At the current scale (five org-wide agents, low change frequency) this is
kept in sync by hand — if these agents multiply or drift becomes a real
problem, revisit whether `context_render.py` should grow a third output
target for the exported `neeve-ai/.github-private` repo's `agents/*.agent.md`,
the same way it already renders `AGENTS.md`/`copilot-instructions.md`/
`CLAUDE.md`/`.cursorrules` into every product repo.

## Recommended usage pattern

For a customer-facing feature end to end, the intended sequence pulls in
multiple agents/skills, not just one:

```
neeve-pm-partner        ← is this the right thing, for the right reason, scoped right
      ↓
   to-spec               ← turn it into a Neeve-format spec
      ↓
neeve-design-partner     ← (if UI) DLS fidelity + accessibility + failure-state design
      ↓
 implement-spec          ← build it; 7 quality gates
      ↓
neeve-security-partner   ← adversarial security pass, OWASP + pentest mindset
      ↓
   code-review           ← general engineering review (SOLID, smells, typing)
```

Not every change needs every stage — a small bug fix doesn't need
`neeve-pm-partner`, and a backend-only change doesn't need
`neeve-design-partner`. Use judgment about which stages apply, the same way
`spec_based_development` is opt-in per repo in `neeve-copilot`.
