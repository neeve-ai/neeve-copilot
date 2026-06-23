# Quality Gates — Production Standard

Every task that produces or modifies code must pass all applicable gates before being
declared done. These gates apply across all skills. A gate marked N/A must be explicitly
justified — it cannot be silently skipped.

---

## Gate 1 — Linter

- Run the project linter and achieve **zero warnings, zero errors**.
- Do not suppress warnings with inline ignore comments unless the suppression is
  pre-existing and unrelated to the current change.
- Common commands (check project config — do not guess):
  - Python: `ruff check .` or `flake8`
  - TypeScript/JS: `npm run lint` or `eslint src/`
  - Go: `golangci-lint run`

**Blocked if:** any new lint error or warning is introduced by the change.

---

## Gate 2 — Strict Type Checking

- Run the type checker in **strict mode** with zero errors.
- Do not use `Any`, `object`, untyped `dict`, or `# type: ignore` to bypass errors
  introduced by this change.
- Common commands:
  - Python: `mypy --strict` (or project-configured mypy settings)
  - TypeScript: `tsc --noEmit` with `"strict": true` in `tsconfig.json`
  - Go: compiler errors are type errors — `go build ./...` must pass

**Blocked if:** any new type error is introduced, or `Any`/`ignore` is added to silence
a type error the change created.

---

## Gate 3 — Unit Tests

- All existing unit tests must pass.
- New behavior introduced by the change must have unit tests covering:
  - [ ] Happy path
  - [ ] Edge cases named in the spec (null inputs, empty collections, boundary values)
  - [ ] Error paths (invalid input, missing dependency, expected exceptions)
  - [ ] Idempotency where the spec requires it
- **Coverage target:** ≥ 95% line and branch coverage on changed modules.
- Every test must carry a `# spec: AC-xx` annotation linking it to an acceptance criterion
  when a spec exists for the change.

**Blocked if:** any test fails, coverage drops below 95% on changed modules, or new
behaviour has no test.

---

## Gate 4 — Integration Tests

- Key end-to-end flows touched by the change must have integration tests.
- Integration tests must use realistic data shapes — not trivially minimal mocks.
- Tests must cover:
  - [ ] The primary success flow
  - [ ] At least one failure or rejection path
  - [ ] Behaviour under concurrent access if the change touches shared state
- Integration tests must be runnable with a single command.

**Blocked if:** no integration test covers the primary flow of the change.

---

## Gate 5 — Scale and Load Considerations

For changes that affect request-handling paths, data-write paths, or background workers:

- Document the expected load profile: requests/second, record volume, message throughput.
- Identify any N+1 query patterns, unbounded scans, or missing indexes introduced.
- If a load test exists, run it and confirm no regression in p95 latency or throughput.
- If no load test exists, add a note in the spec or PR describing the scale assumption
  and any risk that must be monitored post-deploy.

**Blocked if:** an N+1 query or unbounded scan is introduced without a documented
mitigation or accepted risk note.

---

## Gate 6 — Security

Check the following for every change:

- [ ] No secrets, tokens, or credentials in code or logs.
- [ ] All external inputs validated at the boundary (request body, env vars, CLI args).
- [ ] No SQL/command/template injection surface introduced.
- [ ] Auth checks are not bypassable on new routes or methods.
- [ ] No new `eval`, `exec`, `subprocess.shell=True`, or equivalent without explicit review.
- [ ] PII is not logged in plain text.
- [ ] Dependencies added are not known-vulnerable (`pip audit`, `npm audit`, `govulncheck`).

**Blocked if:** any of the above checks fails.

---

## Gate 7 — Code Review

Before marking a task done, run the `code-review` skill. The review must confirm:

- [ ] No logic errors or off-by-one conditions in the changed paths.
- [ ] Error handling is explicit — no silent swallows.
- [ ] Naming is accurate to behaviour (names match what the code actually does).
- [ ] No dead code or commented-out blocks introduced.
- [ ] No hardcoded values that should be config.
- [ ] The change is the minimum required — no speculative additions.

**Blocked if:** `code-review` surfaces any 🔴 Critical or 🟠 High finding unresolved.

---

## Gate Summary Checklist

Emit this at the end of any implementation task before declaring done:

```
## Quality Gate Sign-off

| Gate | Status | Command run / evidence |
|---|---|---|
| 1 Linter — zero warnings | ✅ / ❌ / N/A | |
| 2 Type checker — strict, zero errors | ✅ / ❌ / N/A | |
| 3 Unit tests — all pass, ≥ 95% coverage | ✅ / ❌ / N/A | |
| 4 Integration tests — primary flow covered | ✅ / ❌ / N/A | |
| 5 Scale — N+1 / unbounded scan check | ✅ / ❌ / N/A | |
| 6 Security — inputs, auth, secrets, deps | ✅ / ❌ / N/A | |
| 7 Code review — no 🔴 / 🟠 unresolved | ✅ / ❌ / N/A | |
```

Any ❌ blocks the task. Any N/A must include a one-line justification.
