---
description: Targeted, question-driven trace through this repo's actual code
---
Use the `repo-ask` skill. Answer strictly from what the code does — the
codebase is the source of truth, not this repo's docs, ADRs, or assumptions
carried over from a previous session. If no question was given, ask what to
trace before proceeding. If the traced path touches auth, a trust boundary,
tenant-scoping, or secrets, state the production consequence of what the code
actually does, even if not asked.
