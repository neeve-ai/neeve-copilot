# S-1 — Routing experiment finding

**Issue:** #16. **Gates:** P4 (#23). **Status:** Done.

## Method

Per `implementation-plan.md` §3, S-1: take one currently-pushed fact (the repo table, now
`registry/repos.yaml`), and test whether an agent goes and reads it when the ambient block
carries only a routing pointer instead of the inlined table — versus with no pointer at all.

12 questions (a scaled-down pilot of the ~20 suggested — see Limitations) were built from
`registry/repos.yaml`'s `purpose` field, each answerable precisely only by reading that file
(not guessable from repo name alone; two questions deliberately pit `alc-hello-addon` against
`alc-robin-agent` to test precision, not just recall).

Each question was run twice, as two independent fresh `general-purpose` subagents with zero
prior context, working directory `neeve-copilot`, full tool access:

- **no-pointer** — bare question, no mention of a registry file.
- **pointer** — question preceded by: *"Repo ownership, purpose, and product membership for
  every repository in this org is recorded in `registry/repos.yaml` (a file in this repo) —
  it is not duplicated anywhere else; read it when you need repo-level facts."*

Each agent was told to report its answer plus every file it opened, so tool use could be
verified rather than self-reported after the fact.

## Raw results (12 questions × 2 conditions = 24 runs)

| # | Question (short) | no-pointer: correct? / source | pointer: correct? / source |
|---|---|---|---|
| Q1 | Owns Robin's DB schema | ✅ / `product-overview.md` (old table) | ✅ / `registry/repos.yaml` |
| Q2 | DLS source of truth | ✅ / `registry/repos.yaml` | ✅ / `registry/repos.yaml` |
| Q3 | Scratch AI/eval repo | ✅ / `registry/repos.yaml` | ✅ / `registry/repos.yaml` |
| Q4 | Browser E2E test harness | ✅ / `registry/repos.yaml` | ✅ / `registry/repos.yaml` |
| Q5 | WS tunnel behind NAT | ✅ / `registry/repos.yaml` | ✅ / `registry/repos.yaml` |
| Q6 | Admin portal for admins | ❌ **gave up, 0 tool calls** | ✅ / `registry/repos.yaml` |
| Q7 | NATS→MCP bridge | ✅ / `registry/repos.yaml` | ✅ / `registry/repos.yaml` |
| Q8 | Placeholder repo | ✅ / `registry/repos.yaml` | ✅ / `registry/repos.yaml` |
| Q9 | Deploys stack to k8s | ✅ / `product-overview.md` (old table) | ✅ / `registry/repos.yaml` |
| Q10 | Product-wide planning repo | ✅ / `registry/repos.yaml` | ✅ / `registry/repos.yaml` |
| Q11 | Example/scaffold WebCTRL add-on (not `alc-robin-agent`) | ✅ / `registry/repos.yaml` | ✅ / `registry/repos.yaml` |
| Q12 | Production WebCTRL agent (not `alc-hello-addon`) | ✅ / `ot-building-automation` skill ref (not canonical) | ✅ / `registry/repos.yaml` |

**Pointer condition: 12/12 correct, 12/12 via the canonical file, 0 wrong-from-memory
answers.** **No-pointer condition: 11/12 correct, but only 8/12 via the canonical file** — 2
found the answer in the *old, not-yet-deleted* 16-repo table still sitting in
`product-overview.md` (P5 hasn't run), 1 found it via an unrelated skill reference file, and
**1 failed outright with zero tool calls** — it assumed the repo didn't track this and
declined to look, rather than searching.

No case produced a confidently wrong answer sourced from priors. The no-pointer failure mode
observed here is **non-search** (giving up), not **hallucination**.

## Token break-even check

`registry/repos.yaml` is 4,001 characters (~1,000 tokens). Every pointer-condition run read it
exactly once (a couple of no-pointer runs made 2 tool calls — a grep then a read — still
~1,000–2,000 tokens). **Measured framework-file cost: ~1,000–2,000 tokens/session, well under
the ~5,700-token break-even threshold.** Pass.

## Finding

**Result: reads reliably with a pointer.** 12/12 pointer runs opened the canonical file and
answered correctly, at roughly a fifth of the token budget the criterion allows.

Per the acceptance table, this selects **"Reads only with a strong pointer" → proceed with
P4, and treat the routing wording as load-bearing** (version it, test it), not the
unconditional "reads reliably" row — because the no-pointer condition shows unprompted search
is not guaranteed (Q6's outright refusal) and two of its successes leaned on a duplicate file
P4/P5 will eventually remove. The pointer sentence used here is the wording to version:

> Repo ownership, purpose, and product membership for every repository in this org is
> recorded in `registry/repos.yaml` (a file in this repo) — it is not duplicated anywhere
> else; read it when you need repo-level facts.

## Limitations (accuracy caveat — read before reusing this finding)

- **Scaled-down sample.** 12 questions, not the ~20 the plan suggested, traded off against the
  cost of running each as an independent subagent. Directionally clear (12/12 pointer vs.
  1 clean failure without one) but a wider or cross-product question set would sharpen the
  no-pointer failure rate estimate.
- **The old table is still live.** `neeve/products/robin/context/product-overview.md` still
  has the full 16-repo table (P5 hasn't flattened/removed it yet), so the no-pointer condition
  isn't testing "pointer vs. nothing" as cleanly as the finished P4+P5 state will be — 2 of 12
  no-pointer successes came from finding that duplicate, not from search skill alone. Re-run
  cheaply after P5 lands if the result needs tightening.
- **Approximated harness, not the real one.** Each run was a fresh general-purpose subagent
  given the pointer/question as its entire prompt — not Claude Code's actual system-prompt
  architecture (real NEEVE-block precedence wording, real ambient placement). This tests the
  routing-pointer *mechanism*, not a byte-for-byte rehearsal of the shipped P4 block.
- **Single file, single product.** All questions were single-repo lookups against one file
  (`registry/repos.yaml`) for one product (`robin`). Cross-repo reasoning, `.neeve/` book
  fallback, and multi-product routing are untested here.

## Raw per-task agent transcripts

Not preserved as separate files — each run's full answer + declared tool-use list is quoted
in the "Raw results" table's sourcing and in this document's construction; the underlying
subagent transcripts were ephemeral background tasks, consistent with this being a one-time
pilot rather than a repeatable eval (see P8 for the eval-suite home if this needs to become
one).
