# neeve-copilot/neeve/org — CI sync-check only

## What used to be here, and why it moved or retired

This folder used to hold `PRINCIPLES.md` (the reasoning-lineage charter) and
stage two agent generations: five agents originally gated on a
GitHub-Enterprise-only export path that reached zero engineers, then four of
them migrated to `neeve/agent-src/` (then at products/robin/agents-src) to reach every engineer
through the render pipeline instead. That migration was the right call at the
time — see git history on this file for the full account — but it left eight
narrow specialist agents (`to-prd`, `to-erd`, `repo-guide`,
`neeve-reviewer`, `neeve-security-partner`, `neeve-pm-partner`,
`neeve-design-partner`, plus the placeholder `neeve-ot-specialist`) doing
overlapping jobs with real content duplication against the skills that
already existed (`code-review`'s security/principles references, `neeve-dls`,
`to-spec`).

**This has now been restructured, not just migrated again:**

- `PRINCIPLES.md`'s content lives at `neeve/foundation.md` (company identity,
  culture, product, customers, personas) and `neeve/engineering-principles.md`
  (the SDLC process principles), reorganized around the Design Loop's stages
  rather than a Product/Design/Engineering department split.
- `to-prd` and `to-erd` are now skills (`neeve/skills-src/
  to-prd/`, `to-erd/`) instead of agents — this makes them auto-trigger in
  GitHub Copilot too, where a custom agent only ever appeared in a picker.
- `repo-guide`, `neeve-reviewer`, `neeve-security-partner`,
  `neeve-pm-partner`, and `neeve-design-partner` retired outright — their
  distinct, non-duplicated content (escalation framing, PM/design checklists)
  was folded into `code-review/references/security.md`, the new
  `neeve/references/pm-lens.md` and `neeve/references/design-review.md`, and
  `repo-ask`/`repo-intel`; everything else in them was already present in an
  existing skill and would have drifted as a second copy of the same rubric.
- A single unified agent, `neeve` (`agents-src/neeve/AGENT.md`), replaces the
  eight — it routes to the right skill for each Design Loop stage instead of
  being one more thing to pick from a list of specialists.
- The OT specialist placeholder is deleted; `ot-building-automation` (a
  skill) remains the sole carrier for that domain content, gated on the same
  SME-review bar it always was.

## What's still here

Only `scripts/check_org_sync.py` — the CI check that keeps the unified
agent's routing table, `code-review/references/security.md`'s headings, and
the new reference files' citations of `foundation.md`/
`engineering-principles.md` from silently drifting apart. Read its module
docstring for exactly what it asserts.

## Recommended usage pattern

See `neeve/engineering-principles.md`'s "How This Charter Is Used" section —
the Design Loop sequence through the skills, not a list of agents to
remember.
