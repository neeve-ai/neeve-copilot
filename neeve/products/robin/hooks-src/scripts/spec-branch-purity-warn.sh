#!/usr/bin/env bash
# Warn-only PreToolUse hook: fast local echo of the spec/feat branch-purity
# rule enforced by CI (see .github/workflows/spec-review.yml). Never blocks —
# the CI gate is the actual authority, since editing outside the agent would
# bypass a hook anyway. This only shortens the feedback loop.
set -uo pipefail

payload="$(cat)"

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
case "${branch}" in
  spec/*) ;;
  *) exit 0 ;;
esac

file_path="$(printf '%s' "${payload}" | grep -o '"path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*"path"[[:space:]]*:[[:space:]]*"//; s/"$//')"
[[ -z "${file_path}" ]] && file_path="${payload}"

case "${file_path}" in
  *.py|*.ts|*.tsx|*.js|*.jsx)
    echo "[neeve-hooks] WARNING: editing ${file_path} on spec branch '${branch}'. Specs and implementation are reviewed separately (spec/<TICKET> vs feat/<TICKET>) — CI will fail this PR on spec-branch-purity if a source file lands here. Confirm this is intentional." >&2
    ;;
esac

exit 0
