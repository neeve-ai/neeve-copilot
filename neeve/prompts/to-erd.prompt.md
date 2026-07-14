---
description: Break a PRD into a compliance-aware, dependency-ordered Engineering Requirements Document of WI-* work items
---
Use the `to-erd` skill. If no source PRD is given, ask for its path before
proceeding — the PRD (and prototype branch, if any) is the source of truth.
Ground every work item's `Key files to create/change` in the actual repo(s),
not the PRD's prose; every item carries a `**Compliance:**` field (populated
or an explicit "N/A — no compliance-relevant surface"), and every dependency
appears both in prose and in the mermaid dependency graph, matching exactly.
Hand off to `to-spec` unmodified — one invocation per WI-* item.
