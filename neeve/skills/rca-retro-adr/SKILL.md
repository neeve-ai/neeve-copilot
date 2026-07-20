---
name: rca-retro-adr
description: >
  Capture the three lightweight process artifacts that don't belong to any single Design
  Loop stage: a structured Root Cause Analysis for an incident or bug, a sprint/weekly
  retrospective read from real git history, and a decision-time Architecture Decision
  Record. Trigger on: "do an RCA for...", "root cause this", "run a retro", "sprint
  retrospective", "capture an ADR", "record this decision", "write up this incident", or
  any request to produce a postmortem, retrospective, or decision record.
---

# RCA / Retro / ADR

Three related, deliberate, occasional capture workflows — grouped in one skill because
they share a shape (a structured artifact written from real git/incident history, never
invented) and because none of them owns a Design Loop stage the way `to-spec` or
`code-review` do. Each mode below is independent; pick the one the request actually asks
for.

**Shared discipline across all three modes:** every claim in the artifact must trace to
something real — a commit, a file, a log line, a conversation the user actually had.
Never invent a root cause, a velocity number, or a rationale that wasn't stated. If
something is unknown, write `[unknown — needs author input]` rather than guessing (same
convention `repo-intel`'s ADR stub template already uses).

---

## Mode: RCA (Root Cause Analysis)

For a specific incident or bug that already happened.

### Workflow

1. **Restate the incident** in one sentence: what broke, who/what was affected, when.
2. **5 Whys** — ask "why" against the previous answer until you reach a cause that is
   actually fixable (a process gap, a missing check, a wrong assumption) rather than
   stopping at the first symptom. Cite the file/commit/log evidence for each "why" where
   one exists; mark `[unknown]` where it doesn't.
3. **Contributing factors** — anything that made the incident worse or harder to catch
   (missing test, missing alert, missing gate) — this is where `code-review`'s
   `references/security.md` Security Gates table is useful context if the incident
   touched a security-relevant surface.
4. **Corrective actions** — concrete, assignable follow-ups (not "be more careful").
   Distinguish immediate fix (already shipped) from systemic fix (prevents recurrence).
5. **Write the report** using `references/rca-template.md`, to
   `.help/reports/rca/<YYYY-MM-DD>-<slug>.md` in the repo the incident happened in.
6. **State production consequence and gaps explicitly** — per the house rules' universal
   requirement: what broke, who noticed, blast radius, and whether a rollback/kill-switch
   existed at the time.

If root-causing requires tracing an unfamiliar call chain to its actual persistence/cache
boundary rather than a surface-level guess, invoke `debug-trace` for that step instead of
guessing at step 2.

---

## Mode: Retro (Sprint/Weekly Retrospective)

For a time window (default: the last 7 days), not a single incident.

### Workflow

1. **Confirm the window** — default 7 days; accept `24h`/`14d`/`30d` if the user states
   one.
2. **Pull real git history** for that window: `git log --since=<window> --oneline`,
   merged PRs if `gh` is available, and the active session/plan artifacts if the repo has
   any — never invent a shipped-work summary from memory.
3. **Summarize, grounded**: what shipped (grouped by theme, not commit-by-commit), what's
   still in flight, any velocity/streak observation that's actually derivable from the
   data (e.g. commit cadence) — state it as an observation with its evidence, not a
   score.
4. **Write the report** using `references/retro-template.md`, to
   `.help/reports/retros/<YYYY-MM-DD>-<slug>.md`.
5. Keep it short — a retro nobody rereads next sprint has failed at its one job.

---

## Mode: ADR (Decision-Time Capture)

For a real architectural/technical decision being made **right now** — the live
counterpart to `repo-intel`'s retrospective ADR stubbing (its Phase 6c, which stubs
decisions already visible in old code). This mode captures a decision as it's made, with
full context available, rather than reconstructing it later from code archaeology.

### Workflow

1. **Confirm this is decision-worthy** — per `repo-intel`'s own bar: choosing between
   competing architectures, adopting/replacing a dependency, changing a data model, or
   setting a convention future work must follow. Not every choice needs an ADR.
2. **Write it using the same template and location `repo-intel` already uses** —
   `neeve/skills/repo-intel/references/adr-stub-template.md`, filed at
   `docs/adr/ADR-NNNN-<slug>.md` in the target repo (the convention `repo-intel/SKILL.md`
   states — cite that file directly rather than duplicating the template here; there is
   exactly one ADR home per repo, not a second one this mode introduces).
3. Unlike a retrospective stub, this mode should have **no `[unknown — needs author
   input]` markers** if the decision was actually just discussed — the whole point of
   capturing it live is that the context is available now. If something genuinely is
   still undecided, say so plainly rather than filling in a stub-style placeholder.
4. **Alternatives Considered and Consequences must be real**, not template boilerplate —
   this is the difference between this mode and a code-derived stub: a live decision has
   an actual rejected alternative and an actual accepted tradeoff to record.

---

## Quality Rules (all three modes)

- Never invent a cause, a metric, or a rationale. Write `[unknown]` and move on.
- Cite file paths, commit hashes, or timestamps for every factual claim.
- Prefer one accurate paragraph over three padded ones — these are working documents,
  not ceremony.
- State production consequence and gaps explicitly on anything that reached production
  (mandatory for RCA; situational for ADR/Retro) — per the house rules' universal
  requirement, not a special rule invented for this skill.
- If the report reveals a missing test, missing gate, or missing rollback story, name it
  as a gap in the report itself — don't let it disappear once the retro/RCA is filed.

## Anti-Patterns

- Do not write an RCA that stops at the first symptom ("the deploy failed") without
  reaching a fixable cause.
- Do not write a retro that's a raw commit list with no synthesis.
- Do not stub an ADR's Alternatives/Consequences with placeholder text when the decision
  was just discussed live — that defeats the reason this mode exists.
- Do not create a second ADR directory/convention — always the one `repo-intel` already
  established for this repo.

---

## Skill Chain

| Situation | Next skill |
|---|---|
| RCA reveals a missing test or gate | → `to-spec` (spec the fix) or `code-review`'s `references/security.md` if security-relevant |
| RCA reveals the fix is already shipped but needs verification | → `debug-trace` or `repo-ask` |
| ADR captures a decision that changes how future code should be written | → cite it from the relevant `to-spec`/`implement-spec` work going forward |
| Retro reveals unfamiliar territory in what shipped | → `repo-ask` / `repo-intel` |

**Feeds into:** `to-spec`, `code-review`, `repo-ask`
**Fed by:** an incident, a time window, or a decision being made — not another skill
