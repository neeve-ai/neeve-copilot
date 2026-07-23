---
name: debug-trace
description: >
  The maximal-depth grounding discipline for anything that cannot rest on a
  shallow grep or a training-data guess: trace every method and sub-method in
  the actual call chain all the way to its persistence/cache/external boundary,
  research any concept/package/library/tool for real rather than answering
  from memory, ground the exact version actually running (from the repo or by
  asking) rather than assuming, then translate the finding into plain language
  and state its production consequence for Neeve and its customers. Meant to
  be invoked BY other skills and agents whenever their own workflow reaches a
  step that requires this depth, not only invoked directly. Trigger on: "trace
  this thoroughly", "don't just grep this", "dig into this properly", "ground
  this for me", "what does this actually do end to end", "investigate this bug
  fully", "what version/library is this really", "I don't trust a surface
  answer here".
---

# Debug Trace

This skill is the answer to "a normal trace isn't rigorous enough here." It
exists for the moments a shallow grep, a plausible-sounding function name, or
a remembered fact about a library would be dangerous to rely on — a
production incident, a security-relevant path, an unfamiliar external
dependency, or any point where another skill's own workflow flags that it
needs this level of grounding before it can responsibly continue.

**This is not `repo-ask`.** `repo-ask` deliberately goes "no deeper than
necessary" to answer a specific question — that's the right default for most
questions. `debug-trace` is the opposite default: exhaustive by design,
invoked precisely when "necessary" isn't good enough. See "When To Use This
Instead of `repo-ask`" below before invoking either.

## Why This Matters Here Specifically

Neeve's code frequently sits upstream of physical building equipment
(`context/base.md`'s Why This Matters). A wrong belief about how a call
chain actually persists or caches data, or an outdated assumption about how a
dependency currently behaves, is not just an engineering miss here — it can
mean an operator or a piece of OT equipment acting on a misunderstanding that
nobody actually verified. Depth is the whole point of this skill; treat
"good enough" as a signal to keep going, not a stopping point.

## Core Rules — mandatory whenever this skill is invoked

1. **Trace every method and sub-method in the chain, not just far enough to
   answer.** Follow every branch, retry, background job, event handler, and
   cache read/write, all the way to the final persistence, cache, or external
   boundary — not the first plausible stopping point. A trace that answers
   the question but stops short of a DB write, a cache set, or a queue publish
   it passed through on the way is incomplete here, even if it "answers" the
   original ask.

2. **Never answer from training-data memory about a concept, package,
   library, framework, protocol, or tool — research it for real before
   forming an opinion.** Treat your own prior knowledge of how a piece of
   external tech behaves as a hypothesis to verify, not a fact to state.
   Look it up (WebSearch/WebFetch, or the tool's own installed docs/CLI
   `--help`) before concluding anything about it. This is the same discipline
   the `claude-api` skill already enforces specifically for anything
   Claude/Anthropic-shaped — apply it here to every other external dependency
   too, not just that one case.

3. **Ground the version, don't assume it.** Behavior changes across versions,
   and a correct answer about the wrong version is a wrong answer. Before
   trusting anything researched externally, check what's actually running in
   this environment — a lockfile (`package-lock.json`, `poetry.lock`,
   `go.sum`, `Cargo.lock`), a manifest (`package.json`, `pyproject.toml`,
   `requirements.txt`, `go.mod`), an installed-package query (`pip show`,
   `npm ls`, `go list -m`), or a Helm values file for a deployed service. If
   the version can't be determined from the repo, ask the user directly
   rather than presenting unversioned, researched-but-ungrounded behavior as
   fact about this codebase.

4. **Translate every finding into plain language.** State the conclusion so a
   non-technical reader — a PM, a facilities/security-ops customer, a support
   engineer — could follow it without reading the trace itself. Technical
   precision belongs in the trace; the summary needs none of its jargon.
   Name the concrete thing that happens ("every alarm acknowledgment gets
   written to Postgres and then cached in Redis for 5 minutes"), not an
   abstraction of it ("the acknowledgment flow persists state").

5. **State the consequence and impact for Neeve and its customers in
   production.** Every trace concludes by applying — not re-deriving —
   `context/fragments/production-consequence-and-gaps.md`'s Consequence
   and Gaps discipline: what breaks if this is wrong, who notices, blast
   radius, and rollback story where relevant. Frame it against Neeve's actual
   customer reality from `context/base.md`'s Why This Matters and Product
   Overview: an operator watching a building system, OT equipment upstream of
   this code, or a facilities/security-ops team relying on Robin staying
   advisory-only. Don't repeat the discipline's text — apply it to this
   specific trace's finding.

---

## Workflow

### Phase 0 — Scope the Trace

State plainly what triggered this level of rigor (a production incident, an
unfamiliar dependency, a security-relevant path, another skill's workflow
flagging it) and what the exhaustive trace needs to reach — a specific
persistence/cache boundary, a specific external service, or "as far as
first-party code goes." Unlike `repo-ask`, do not scope this down to the
minimum — scope it to the full boundary the situation actually requires.

If this repo has a committed OKF book, read `index.md` first to locate the
entry point/module before mapping the call graph cold, note its guarded
surfaces and stack up front, and check `appendix.md` for any symbol already
documented on the path — the same mandatory check every pipeline skill now
performs, not optional here either. The book is a map, not proof: this
skill's whole purpose is grounding claims in real, current behavior, so
verify anything the book states against the actual code before trusting it
in the trace — an exhaustive trace that cites a stale book entry as fact is
a worse outcome than one that grepped cold and got it right.

### Phase 1 — Exhaustive Call-Chain Mapping

Starting from the entry point, build the full call graph rather than the
single answer path:

- Follow every method and sub-method actually reachable from the entry point
  that's relevant to the traced concern — not just the first branch that
  looks right.
- Continue through retries, background/async jobs, event publishers and
  subscribers, and middleware — these are common places a "complete-looking"
  trace actually stops short.
- Follow the chain all the way to its persistence boundary (a DB write/read),
  its cache boundary (a cache get/set/invalidate), or an external
  service/API boundary — whichever the entry point actually reaches. Name the
  boundary explicitly when reached; do not speculate past it.
- Cite file and line for every hop, the same discipline `repo-ask` already
  applies — depth does not relax citation rigor.

### Phase 2 — External Grounding Pass

For every concept, package, library, framework, protocol, or tool the trace
touches that isn't this repo's own first-party code:

- State the hypothesis (what you believe it does, from training knowledge).
- Research it for real (WebSearch/WebFetch, official docs, changelog) before
  treating the hypothesis as fact.
- Ground the version actually in use here (lockfile/manifest/installed-package
  query/Helm values — see Core Rule 3) and confirm the researched behavior
  matches that version specifically, not just "the library" in the abstract.
- If the version can't be determined and it matters to the answer, ask the
  user rather than guessing.
- Note explicitly where the hypothesis and the researched reality diverged —
  that divergence is itself a finding, not a footnote.

### Phase 3 — Plain-Language Translation and Consequence

Write the finding twice, deliberately:

1. **The trace itself** — technical, cited, file:line precision, for an
   engineer verifying the work.
2. **The plain-language summary** — what actually happens, in one or two
   sentences a non-technical reader can act on, followed by the Consequence
   and Gaps block per Core Rule 5.

### Phase 4 — Confidence and Gaps

Same shape as `repo-ask`'s confidence block, adjusted for exhaustiveness:

```
**Confidence:** [High / Medium / Low]
**Traced to:** [the actual persistence/cache/external boundary reached]
**Externally grounded:** [each non-first-party concept researched, with the
  version confirmed and the source checked]
**Gaps:**
- [any hop not fully traced, any version that couldn't be confirmed, any
  external boundary not readable from here]
**Consequence for Neeve / customers in production:**
- [per context/fragments/production-consequence-and-gaps.md]
```

A trace that reaches "High" confidence without an explicit persistence/cache
boundary named, or without every external concept's version grounded, has not
actually met this skill's bar — treat that as incomplete, not merely cautious.

---

## When To Use This Instead of `repo-ask`

| Situation | Use |
|---|---|
| A specific, scoped question with an obvious answer path | `repo-ask` |
| A production incident or anything customer-facing went wrong | `debug-trace` |
| The trace touches auth, a trust boundary, tenant-scoping, or secrets | `debug-trace` |
| The trace depends on an unfamiliar package/library/tool's actual behavior | `debug-trace` |
| Another skill/agent's own workflow explicitly flags "this step needs depth" | `debug-trace` |
| Understanding existing behavior before writing a spec, in a hurry | `repo-ask` |

When in doubt and the cost of being wrong is production-facing, prefer
`debug-trace`.

## How Other Skills and Agents Invoke This

Any skill or agent whose own workflow reaches a step that matches the table
above should invoke this skill by name at that step, the same way
`implement-spec`/`code-review` point at `references/security.md` rather than
re-deriving a security checklist inline — don't fork this methodology into
another skill's file, reference it. A skill/agent's own doc should name the
specific step where this applies (e.g. "before proposing a fix that touches
an unfamiliar library, invoke `debug-trace`"), not blanket-require it on every
invocation — most steps don't need this depth, and treating this as
mandatory everywhere would make every task as slow as an incident response.

## Disclosure Requirement (the mechanical backstop for invoking skills/agents)

There is no way to mechanically verify that another skill or agent actually
invoked `debug-trace` before making a claim — that decision happens upstream,
in a model's own judgment, and no CI check can see into that. What *can* be
enforced is that the claim's output never stays silent about it. Any skill or
agent whose own doc points here must include one line in its own output,
every time it makes a claim of the kind in "When To Use This Instead of
`repo-ask`" above:

```
**Depth check:** [debug-trace invoked — see citation] | [not needed — reason] | [needed, not invoked — flagged as a gap]
```

The third option matters most: if a step recognizes in hindsight that this
depth was warranted but wasn't applied, that omission is written down as a
gap (per `context/fragments/production-consequence-and-gaps.md`'s "a gap
is a line item, not a silence"), not quietly dropped. This doesn't force
compliance — a skill that skips the disclosure line has skipped the whole
thing again, invisibly, and no tooling here closes that residual gap. What
it does do is turn most omissions into a visible, reviewable line instead of
an untraceable one, and gives `code-review`'s Gate 4 backstop something
concrete to check for.

## Skill Chain

`debug-trace` is a context-gathering and diagnostic skill, one level more
rigorous than `repo-ask`. It doesn't replace the pipeline — it grounds a
single step of it when that step specifically demands it.

| Situation | Next skill |
|---|---|
| Trace reveals the actual root cause of a bug → write a spec for the fix | → `to-spec` |
| Trace confirms enough grounding to implement a known fix | → `implement-spec` |
| Trace reveals a security-relevant gap | → `code-review` (cite `references/security.md`) |
| Trace was inconclusive — codebase is broadly unfamiliar | → `repo-intel` |

**Feeds into:** `to-spec`, `implement-spec`, `code-review`
**Fed by:** any skill or agent step that flags it needs this depth — never a
required first step on its own
