# RCA Template

Use for the RCA mode of `rca-retro-adr`. Write to
`.help/reports/rca/<YYYY-MM-DD>-<slug>.md`. Every field must trace to real evidence —
mark `[unknown — needs author input]` rather than guessing.

---

```markdown
# RCA: [one-line incident summary]

Date: [YYYY-MM-DD]
Reported by: [name, if known]
Severity: [blast radius — one request / one tenant / all tenants / platform-wide]

## What Happened

[One paragraph: what broke, who or what was affected, when it was noticed, when it was
resolved.]

## Timeline

| Time | Event |
|---|---|
| [time] | [detection / escalation / mitigation / resolution — cite log/commit/alert where possible] |

## 5 Whys

1. Why did [the symptom] happen? → [answer, cite evidence]
2. Why did that happen? → [answer, cite evidence]
3. Why did that happen? → [answer, cite evidence]
4. Why did that happen? → [answer, cite evidence]
5. Why did that happen? → [root cause — the fixable one, not another symptom]

## Contributing Factors

- [Missing test / missing alert / missing gate / process gap — name each one explicitly]

## Corrective Actions

| Action | Type | Owner | Status |
|---|---|---|---|
| [concrete, assignable fix] | Immediate / Systemic | [who] | [done / planned] |

## Production Consequence (at the time)

- **What broke:** [specific failure mode]
- **Who noticed:** [operator / customer / on-call / no one — internal only]
- **Blast radius:** [one request / one session / one tenant / all tenants / platform-wide]
- **Rollback/kill-switch:** [did one exist? was it used? if not, why not]

## Gaps

- [Anything not covered by the corrective actions above — a gap is a line item, not a
  silence. If none, state "none identified — verified via [what was checked]."]
```
