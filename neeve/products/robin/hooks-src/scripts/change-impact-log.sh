#!/usr/bin/env bash
# PostToolUse hook: deterministic, on-disk record of every file the agent
# changed this session (edit/create/write), plus a stderr nudge to state the
# operational consequence — mirrors base.md's "state the operational stakes"
# ethos. The log line is unforgeable (a real script ran on a real tool call);
# the consequence statement itself is a nudge, not a guarantee — CI/PR review
# is the actual gate for that, same warn-only split as the rest of this repo.
#
# Input contract (GitHub Copilot hooks, Public Preview, mid-2026): see
# https://docs.github.com/en/copilot/reference/hooks-reference — field names
# not fully stable yet.
set -uo pipefail

payload="$(cat)"

log_dir=".github/hooks/logs"
log_file="${log_dir}/session-audit.log"
mkdir -p "${log_dir}" 2>/dev/null || exit 0

file_path="$(printf '%s' "${payload}" | grep -o '"path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"path"[[:space:]]*:[[:space:]]*"//; s/"$//')"
if [[ -z "${file_path}" ]]; then
  file_path="$(printf '%s' "${payload}" | grep -o '"\(file_path\|target\)"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"[[:space:]]*:[[:space:]]*"//; s/"$//')"
fi

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

if [[ -z "${file_path}" ]]; then
  echo "${ts}  CHANGE-UNPARSED  branch=${branch}  raw_payload_len=${#payload}" >> "${log_file}"
  exit 0
fi

echo "${ts}  CHANGE  ${file_path}  branch=${branch}" >> "${log_file}"
echo "[neeve-hooks] Changed ${file_path} on branch '${branch}'. State the operational consequence of this change (what breaks, what's exposed, what a customer/operator would notice) before moving on." >&2

exit 0
