---
description: Full codebase scan producing/refreshing the OKF book, README gaps, ADR stubs, spec stubs
---
Use the `repo-intel` skill. Scan this repository and produce (or refresh) its
OKF book (`.help/introduction.md`, `.help/index.md`, `.help/appendix.md`), flag README gaps, and
stub any missing ADRs/specs it implies. If the book already exists, reconcile
it with the current code rather than regenerating from scratch — call out
what changed and why. The Sign-off Report must include trust boundaries and
security/production gaps found — or state explicitly what was checked if none
were found.
