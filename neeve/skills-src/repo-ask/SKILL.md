---
name: repo-ask
description: >
  Answer a specific question about a codebase by strategically tracing through source code.
  Code is always the source of truth — docs and comments are hints, never proof. Always
  clarify intent before searching. Trigger on: "why does X happen", "how does X work",
  "where is X defined", "what happens when X", "trace X", "find where X is called",
  "explain this flow", "why is this failing", "what owns X", "how does X get triggered",
  "show me how X connects to Y", or any question about runtime behavior, ownership,
  data flow, or causality in a codebase.
---

# Repo Ask

This skill answers a specific question about a codebase by reading code strategically.

The key discipline: **code is always the source of truth**. Comments lie, docs drift, variable
names mislead — but the actual execution path does not. Every answer must be grounded in
what the code does, not what it says it does or what anyone believes it does.

The second discipline: **clarify before searching**. The same question asked in two different
contexts requires two completely different search strategies. Spending 30 seconds on
clarification saves minutes of reading the wrong files.

## What This Skill Does

- Asks the minimum necessary clarifying questions to understand intent.
- Plans a targeted search strategy before reading any file.
- Follows the actual execution path to answer the question.
- Cites file and line numbers for every claim.
- Calls out when docs/comments conflict with code behavior.
- Stops and reports when the answer cannot be determined from available source.

## What This Skill Does Not Do

- Scan the entire repository speculatively.
- Answer from memory, training data, or generic framework knowledge.
- Treat README or docstring content as proof of behavior.
- Guess when evidence is missing — it reports the gap instead.

---

## Workflow

### Phase 0 — Clarify Intent

**This phase is mandatory. Never skip it.**

Before searching for anything, restate the question and surface what is ambiguous.
Ask only the questions that would change the search strategy. Typical clarifiers:

- **Scope:** Is this question about production behavior, a test, a specific environment,
  or all of them?
- **Trigger:** Is the user asking about a runtime event, a function call, a CLI command,
  a request, a background job, or a deployment step?
- **Outcome:** Is the user trying to understand, fix, change, or verify something?
- **Prior knowledge:** Has the user already looked somewhere? What did they find?

Use this shape to confirm before proceeding:

```
**Clarification check**

- **Question as I understand it:** [restate precisely]
- **What I'm treating as the starting point:** [entry point, trigger, or symbol]
- **What outcome I'm targeting:** [understand / fix / trace / verify]
- **Assumptions I'm making:** [list or "none"]
- **Confirm or correct before I search?**
```

If the question is unambiguous and the intent is clear, state the clarification check
inline and proceed immediately — do not force a back-and-forth when none is needed.

**Also check, before searching**: if this repo is registered in `neeve-copilot`'s
`context-src/repos/<repo>.yaml`, note its `do_not_modify` list. If the question is
heading toward a change to something on that list (not just understanding it), say so
in the clarification check — mandatory here, not left to whether the person asking
thought to check separately.

### Phase 1 — Choose a Search Strategy

Before reading any file, decide the minimum search path that can answer the question.
Pick the strategy that reads the fewest files while covering the highest-signal locations.

| Question shape | Starting strategy |
|---|---|
| "Where is X defined / declared?" | `grep -r` for the symbol name; narrow by file type |
| "How does X work?" | Find the entry point for X; read it; follow one level at a time |
| "Why does X fail / behave unexpectedly?" | Find the error site or divergence point first; trace backward |
| "What happens when X is called / triggered?" | Find the caller or event publisher; trace forward |
| "What owns / is responsible for X?" | Find where X is written, mutated, or decided |
| "How does X connect to Y?" | Find X's output / Y's input; trace the path between them |
| "Is X used anywhere?" | `grep -r` for the symbol; list call sites |

**Strategy rules:**
- Start with `grep` or `find` before opening files — locate before reading.
- Read the smallest unit that contains the answer: a function, not a file; a file, not a
  module; a module, not a service.
- Follow imports and call sites one hop at a time. Do not jump ahead.
- Stop reading a branch when it is clearly not on the answer path.
- If the first strategy produces no results, switch strategy before widening scope.

### Phase 2 — Execute the Search

Carry out the planned search. At each step:

1. State what you are about to search and why.
2. Execute the search (grep, find, read).
3. Report what was found before deciding the next hop.
4. If the result is not on the answer path, say so and adjust.

**Code-as-truth rules, enforced at every read:**
- If a comment says X but the code does Y, the code does Y. Note the conflict.
- If a doc says X but the code does Y, the code does Y. Note the conflict.
- If a type annotation says X but the runtime flow does Y, report both.
- If a function name implies X but the implementation does Y, report both.
- Never infer behavior from a function name alone — read the implementation.

**Depth control:**
- Go no deeper than necessary to answer the question.
- If the path goes more than 4–5 hops, pause and confirm with the user that you are on
  the right track before continuing.
- If a hop leads to a third-party library boundary, stop and note it explicitly rather
  than speculating about library internals.

### Phase 3 — Synthesize the Answer

Write the answer in the most useful form for the user's stated outcome:

| Outcome | Answer shape |
|---|---|
| Understand | Plain-English explanation + annotated call chain |
| Fix | Root cause + the exact line to change + why |
| Trace | Numbered step-by-step flow with file:line citations |
| Verify | "The code does X" + evidence cite + any divergence from expectation |

**Answer rules:**
- Every behavioral claim must cite a file and line number.
- If multiple paths are possible (e.g. conditional branching), trace each branch and name
  the condition that selects it.
- If the answer is "it depends", state exactly what it depends on and where that decision
  is made.
- If the question cannot be fully answered from available source, state exactly what is
  missing and where a human would need to look (e.g. "this crosses a NATS boundary —
  the consumer is in service X which was not scanned").
- If the traced path touches auth, a trust boundary, tenant-scoping, secrets, or any
  production config, state the production consequence of what the code actually does —
  even if the question didn't ask about security. A trace that reveals a missing
  tenant-scope check is a finding, not just an answer.

### Phase 4 — Confidence and Gap Report

After the answer, emit a brief confidence statement:

```
**Confidence:** [High / Medium / Low]
**Grounded in:** [list of files read]
**Gaps / unverified:**
- [anything that was inferred, assumed, or crossed a boundary not read]
**Conflicts found:**
- [any doc/comment/name that contradicts the code — cite both]
```

Low confidence means the answer path crossed a boundary not read (another service, an
external system, a generated file, a runtime-only value). Never omit this block — a
reader needs to know how much to trust the answer.

---

## Clarification Heuristics

Use judgment about when to stop and ask vs. proceed:

**Proceed without asking if:**
- The question names a specific symbol, file, or behavior.
- The intent is obvious from the phrasing (e.g. "trace the login flow").
- A clarification check can be stated inline and the user can correct it in the next turn.

**Stop and ask if:**
- The question could mean two completely different things (e.g. "why is auth slow" could
  mean a bug, a design question, or a performance investigation).
- The question involves a word that is likely overloaded in this codebase (e.g. "session",
  "org", "role" — these mean specific things per repo).
- The user's stated outcome would require reading a large surface and the wrong
  interpretation wastes significant effort.

Never ask more than two clarifying questions at once.

---

## Search Discipline

### Do
- `grep -rn "symbol_name" src/` before opening any file.
- Read function signatures before function bodies.
- Follow the import chain to find the actual implementation, not the re-export.
- Check for interface implementations separately from the interface definition.
- When tracing async flows, find the event/message subscriber, not just the publisher.

### Do Not
- Open a file just because its name seems relevant.
- Read an entire file when `grep` already located the relevant lines.
- Trust `# TODO`, `# deprecated`, or `# FIXME` comments as descriptions of current behavior.
- Assume that a function does what its name says without reading the body.
- Stop at an abstract class or interface — find the concrete implementation.
- Speculate about behavior in a service that was not read.

---

## Answer Quality Bar

An answer is complete when:

- [ ] Every behavioral claim cites a file and line.
- [ ] The execution path from trigger to outcome is unbroken (or the break is named).
- [ ] Conditional branches are named with their conditions.
- [ ] Any doc/comment conflicts with the code are surfaced.
- [ ] The confidence and gap block is present.
- [ ] The user's original intent (understand / fix / trace / verify) is addressed directly.

An answer that says "it likely does X" without a code citation is incomplete. An answer
that traces 80% of the path and goes silent at a service boundary is incomplete unless
the boundary is explicitly named as the gap.

---

## Skill Chain

`repo-ask` is a context-gathering and diagnostic skill. Use it as the first step before
any other skill when the codebase is unfamiliar or when a task requires understanding
existing behavior before changing it.

| Situation | Next skill |
|---|---|
| Answer reveals a bug, missing feature, or undefined behavior → write a spec | → `to-spec` |
| Answer reveals broad unfamiliarity with the codebase | → `repo-intel` (full map first) |
| Answer confirms enough context to implement a known spec | → `implement-spec` |
| Answer reveals the change is already implemented but has a defect | → `code-review` |
| Answer reveals a DLS or UI component is wrong | → `neeve-dls` |

**Feeds into:** `to-spec`, `implement-spec`, `code-review`, `neeve-dls`, `repo-intel`
**Fed by:** nothing — this is always a valid starting point

Load `references/quality-gates.md` if the answer leads directly into an implementation task.

