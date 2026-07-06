#!/usr/bin/env bash
# PostToolUse hook: deterministic, on-disk proof that a skill/instruction file
# was actually read in this session — not a claim the model can make up.
# Fires on every file-read tool call; only logs when the path touched is one
# of Neeve's own skill/instruction/context surfaces. Never blocks — exits 0
# unconditionally, same warn-only contract as the other hooks in this repo.
#
# Input contract (GitHub Copilot hooks, Public Preview, mid-2026): a JSON
# payload is piped to stdin. Documented fields: sessionId, timestamp, cwd,
# toolName, toolArgs (raw, shape depends on tool). Field names are not fully
# stable yet — re-verify against
# https://docs.github.com/en/copilot/reference/hooks-reference before relying
# on new fields.
set -uo pipefail

payload="$(cat)"

log_dir=".github/hooks/logs"
log_file="${log_dir}/session-audit.log"
mkdir -p "${log_dir}" 2>/dev/null || exit 0

file_path="$(printf '%s' "${payload}" | grep -o '"path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"path"[[:space:]]*:[[:space:]]*"//; s/"$//')"

# Fallback: some clients name the field "file_path" or "target" instead of "path".
if [[ -z "${file_path}" ]]; then
  file_path="$(printf '%s' "${payload}" | grep -o '"\(file_path\|target\)"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"[[:space:]]*:[[:space:]]*"//; s/"$//')"
fi

if [[ -z "${file_path}" ]]; then
  # Can't identify a path — record the raw event rather than silently dropping it.
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "${ts}  SKILL-LOAD-UNPARSED  raw_payload_len=${#payload}" >> "${log_file}"
  exit 0
fi

case "${file_path}" in
  *skills-src/*/SKILL.md|*.github/skills/*/SKILL.md)
    kind="SKILL"
    ;;
  *.github/instructions/*.instructions.md)
    kind="INSTRUCTIONS"
    ;;
  *.github/prompts/*.prompt.md)
    kind="PROMPT"
    ;;
  *AGENTS.md|*copilot-instructions.md|*CLAUDE.md|*.cursorrules)
    kind="ALWAYS-ON-CONTEXT"
    ;;
  *)
    exit 0
    ;;
esac

ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "${ts}  ${kind}-LOAD  ${file_path}" >> "${log_file}"

exit 0
