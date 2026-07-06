---
description: Turn a problem, bug, or ADR into a Neeve-style spec with a handoff for implement-spec
---
Use the `to-spec` skill. If no target (feature, bug, or ADR) is given, ask what
to spec before proceeding. Follow the canonical Neeve spec template and the
8-check spec-review rubric before handing off — do not skip straight to
`implement-spec`. The spec's Security § Production Consequence and
Consequences/Gaps sections are required, not optional — a spec that omits
blast radius, rollback story, or residual risk is not ready for handoff.
