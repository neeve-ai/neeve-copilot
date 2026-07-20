# Retro Template

Use for the Retro mode of `rca-retro-adr`. Write to
`.help/reports/retros/<YYYY-MM-DD>-<slug>.md`. Grounded in real `git log`/PR history for
the stated window — never an invented summary of what shipped.

---

```markdown
# Retro: [window, e.g. "2026-07-12 to 2026-07-19"]

Repo: [name]
Window: [7d / 24h / 14d / 30d]

## Shipped

[Grouped by theme, not commit-by-commit. Cite commits/PRs.]

- [Theme]: [what shipped] — [commit/PR refs]

## In Flight

- [What's still open, and where — branch, draft PR, active spec]

## Observations

[Only observations actually derivable from the data — commit cadence, size of changes,
recurring type of fix. State the evidence, not a score.]

- [Observation] — evidence: [what was checked]

## What Slowed Things Down (if evident from the data)

- [e.g. a recurring revert, a long-lived branch, a repeated type of bug — cite it]

## Gaps

- [Anything the retro can't speak to because the data wasn't available — state it rather
  than omitting silently. If none, state "none identified — verified via [what was
  checked]."]
```
