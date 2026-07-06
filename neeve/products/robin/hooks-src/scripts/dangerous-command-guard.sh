#!/usr/bin/env bash
# Warn-only PreToolUse hook: flags obviously destructive shell commands.
# Never blocks — exits 0 unconditionally. CI remains the actual hard gate;
# this only shortens the feedback loop inside an agent session.
#
# Input contract (VS Code Agent Hooks, Preview, mid-2026): a JSON payload is
# piped to stdin describing the pending tool call. The exact field names are
# not yet stable — re-verify against
# https://code.visualstudio.com/docs/agent-customization/hooks before
# depending on this in a blocking capacity.
set -uo pipefail

payload="$(cat)"

command_text="$(printf '%s' "${payload}" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*"command"[[:space:]]*:[[:space:]]*"//; s/"$//')"
[[ -z "${command_text}" ]] && command_text="${payload}"

warn() {
  echo "[neeve-hooks] WARNING: ${1}" >&2
}

case "${command_text}" in
  *"rm -rf /"*|*"rm -rf /*"*)
    warn "command looks like it deletes from filesystem root: ${command_text}"
    ;;
esac

case "${command_text}" in
  *"push --force"*"main"*|*"push -f"*"main"*|*"push --force"*"develop"*|*"push -f"*"develop"*)
    warn "force-push to main/develop detected: ${command_text}"
    ;;
esac

case "${command_text}" in
  *"reset --hard"*)
    warn "git reset --hard detected — confirm you're on a scratch branch, not shared work: ${command_text}"
    ;;
esac

exit 0
