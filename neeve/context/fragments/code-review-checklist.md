## CODE REVIEW

Apply the `code-review` skill's SMART review policy — do not re-derive review
criteria from scratch. Its references cover:

- `references/principles.md` — SOLID, clean-architecture layering, dependency direction
- `references/smells.md` — naming anti-patterns, god objects, long methods, dead code
- `references/security.md` — input validation, injection, secrets, auth/authz checks
- `references/typing.md` — type-safety and error-handling conventions per language
- `references/quality-gates.md` — the 7 gates that must pass before a PR is "done"
- `references/kubernetes.md` — Helm/K8s review points, when the change touches deploy shape

Output format, severity tiers (🔴 blocks merge / 🟡 should fix / 🟢 nice to have),
and per-language guidelines (Python/TS/Java/Go/Rust) all live in the skill —
invoke `/code-review` (or `$code-review`) rather than restating its rubric here.
