---
description: Full codebase scan producing CONTEXT.md, README gaps, ADR stubs, spec stubs
---
Use the `repo-intel` skill. Scan this repository and produce (or update) its
`CONTEXT.md`, flag README gaps, and stub any missing ADRs/specs it implies.
If `CONTEXT.md` already exists, reconcile it with the current code rather than
regenerating from scratch — call out what changed and why. The Sign-off Report
must include trust boundaries and security/production gaps found — or state
explicitly what was checked if none were found.
