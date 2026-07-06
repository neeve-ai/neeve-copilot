---
description: SMART production-readiness review — spec/ADR alignment, contracts, correctness, security, Helm
---
Use the `code-review` skill on the current diff (or the PR/branch specified).
Route to the SPEC FILE REVIEW checklist if the change is on a `spec/*` branch,
and to CODE REVIEW otherwise — never blend the two. Report findings tiered
🔴/🟡/🟢 per the skill's output format; do not restate its rubric inline.
Always include the skill's "Production Consequence & Gaps" section — never
close a review without stating blast radius/rollback and naming any gap
(missing security gate, untested path) explicitly, even if "none identified."
