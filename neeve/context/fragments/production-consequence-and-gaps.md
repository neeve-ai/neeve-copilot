## Required in Every Output: Consequence and Gaps

This applies to every skill's output — a spec, a review, an implementation
summary, a traced answer, a design change — not just security-flagged work.
Two things must be stated explicitly, never left implicit or omitted:

### 1. State the production consequence

Name what happens when this ships, in terms someone outside the diff can
verify:

- **What breaks or degrades** if this is wrong — a specific failure mode, not
  "there could be issues."
- **What's exposed** — data, a credential, a tenant boundary — if this is a
  security-relevant change.
- **Who notices** — an operator watching a building system, a customer's
  end user, an on-call engineer, no one (internal-only) — and how.
- **Blast radius** — one request, one session, one tenant, every tenant
  sharing that service, or platform-wide. A single-tenant bug and a
  cross-tenant leak are not the same severity even if the code diff looks
  similar; say which one this is.
- **Rollback or kill-switch story** — for anything customer-facing or
  touching a trust boundary: how does this get turned off fast if it's wrong
  in production, and does that story actually exist yet (feature flag,
  revertable migration, config toggle) or is "revert the deploy" the only
  option.

This is the standard enterprise SaaS operators hold a change to before it
reaches production — not paperwork, the actual question a Google SRE
error-budget review or an AWS COE asks after an incident, asked *before*
shipping instead of after.

### 2. Call out gaps explicitly — a gap is a line item, not a silence

Report what was **not** covered with the same visibility as what was. Never
let an unaddressed risk disappear by omission:

- A security control that applies here but isn't implemented yet (e.g. no
  audit log on a sensitive action, no per-tenant rate limit on a new
  endpoint).
- A test that should exist for this change but doesn't (a concurrency case,
  a cross-tenant case, a malformed-input case).
- A CI/security gate that should be running on this repo but isn't (see
  `references/security.md`'s Security Gates table — treat a missing gate as
  a named gap, not a silent non-issue).
- An assumption that was made because verifying it was out of scope for this
  pass (a downstream service's behavior, a config value, a runtime
  constraint) — name the assumption so the next reader can verify it instead
  of re-discovering that it was never checked.

This is a **Gaps** or **Residual Risk** list, and it is either populated or it
explicitly says "none identified — verified via `[what was checked]`." A
blank space where this list should be is not the same as verifying there
are no gaps; treat it as a finding on the output itself. This is the same
discipline enterprise compliance tooling (continuous-controls-monitoring
platforms like Vanta or Wiz) applies to security posture: gaps are tracked
and visible, not swept into "looks fine" the moment nobody names them.

### Where the depth lives

This fragment is the discipline of always stating consequence and gaps. The
actual security checklist — OWASP coverage, pentest-mindset adversarial
checks, the security-gates table, enterprise multi-tenancy properties — is
`code-review`'s `references/security.md`; use it as the canonical source for
*what* to check, not just this repo's own judgment, whenever the consequence
or gap is security- or compliance-relevant.
