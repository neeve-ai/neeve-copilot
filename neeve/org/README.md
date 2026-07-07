# neeve-copilot/neeve/org — org-wide principles, and `neeve-ot-specialist`'s staging area

## What moved, and why

Four of the five agents originally drafted here —
`neeve-reviewer`, `neeve-security-partner`, `neeve-pm-partner`,
`neeve-design-partner` — have moved to
[`neeve/products/robin/agents-src/`](../products/robin/agents-src/README.md).

The reason: this folder's original design gated all five on exporting to a
separate `neeve-ai/.github-private` GitHub-Enterprise repo — a real GitHub
feature ([Preparing to use custom agents in your enterprise](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-agents/prepare-for-custom-agents)),
but one that requires an Enterprise owner to create that repo and enable an
org-wide setting, neither of which ever happened. Until that setup exists,
these agents reached **zero engineers** — not "fewer engineers than ideal,"
zero, since the export step itself was never done. Meanwhile
`agents-src/`'s render pipeline (`scripts/agents_render.py`, built for
`to-prd`/`to-erd`/`repo-guide`) already reaches every engineer, in every
tool (Claude Code, Copilot, Codex natively; Cursor/Antigravity via a skill
fallback), with no GitHub Enterprise dependency at all. Migrating these four
onto that mechanism was a straight upgrade: same content, actually
distributed, starting immediately — see
[`agents-src/README.md`](../products/robin/agents-src/README.md) for exactly
how each tool receives them.

**This is a deliberate retirement, not an oversight.** If you're looking at
this file wondering whether to resurrect the `.github-private` export path
for those four agents: don't — re-read this section first.

## What's still here

**`PRINCIPLES.md`** stays — it's the reasoning-lineage charter all of
Neeve's specialist agents (the four migrated ones, plus `neeve-ot-specialist`
below) are condensed from. Each principle is adapted from a named practice
at a company strong on that dimension (Amazon, Okta, Google SRE,
Stripe/Linear, Anthropic/OpenAI, Vanta/Wiz, Palantir — see the charter for
which lineage maps to which principle), flavored for Neeve's actual offering
and customer base rather than applied generically. Read it first if you want
the *why* behind any agent's behavior, migrated or not.

**`neeve-ot-specialist`** stays in `.github/agents/` at its current,
`[PLACEHOLDER]`-flagged location. It's gated on a different thing than the
four that moved: the underlying `ot-building-automation` skill needs SME
(Niagara/BQL/WebCTRL) review before its content is trustworthy — that's a
content-readiness gate, not a distribution one, so migrating it to
`agents-src/` today would just distribute unvalidated content further and
faster. Once it's SME-validated, migrate it the exact same way the other
four were: author `agents-src/neeve-ot-specialist/AGENT.md`, delete this
placeholder, add it to `check_org_sync.py`'s `REQUIRED_CITATIONS`.

## Keeping content in sync with `PRINCIPLES.md`

The four migrated `AGENT.md` files intentionally restate a condensed version
of `PRINCIPLES.md`'s reasoning, the same way they did before the move — edit
`PRINCIPLES.md` first when a principle changes, then update the affected
agent(s) in `agents-src/` to match.
[`neeve/org/scripts/check_org_sync.py`](scripts/check_org_sync.py) still runs
in `neeve-copilot`'s CI and asserts each migrated agent still cites the
specific `PRINCIPLES.md`/`security.md` sections it claims to apply, now
pointed at their new `agents-src/<name>/AGENT.md` locations.

## Recommended usage pattern

For a customer-facing feature end to end, the intended sequence pulls in
multiple agents/skills, not just one:

```
neeve-pm-partner        ← is this the right thing, for the right reason, scoped right
      ↓
   to-prd / to-spec      ← turn it into a PRD or a Neeve-format spec
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
