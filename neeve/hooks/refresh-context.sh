#!/usr/bin/env bash
# Runs as a global Claude Code SessionStart hook (installed via
# merge_session_hook.py). Keeps house rules, skills, and the cross-tool
# agents current on this machine without relying on anyone
# remembering to re-run sync_skills.sh — the freshness problem a single
# canonical source doesn't solve by itself (every engineer has their own
# local clone, which is only as fresh as their last pull).
#
# Deliberately a no-op on any day nothing changed upstream: pulls, compares
# HEAD before/after, and only reinstalls if the pull actually moved HEAD.
# This keeps a normal session start fast and quiet — no rebuild, no noise —
# while still closing the loop automatically the day something did change.
#
# Reinstalls by calling install.sh directly (never sync_skills.sh, which
# does its own git pull — that would mean two pulls per refresh) with
# exactly the agent flags recorded in the selection receipt install.sh wrote
# the last time it ran on this machine. Without a receipt (e.g. this is the
# first refresh on a machine that installed before receipts existed), fall
# back to install.sh's own auto-detect (no flags) rather than --all, so this
# never installs into a tool the engineer never selected.
#
# Every run (not just ones that update something) appends one line to a
# local, per-engineer log — user + commit hash + whether the reinstall
# succeeded, so "what commit is this machine actually on, and did the last
# refresh actually work" is a real, inspectable fact instead of a guess.
# This log is local only: it is never pushed, uploaded, or aggregated
# anywhere by this script — that would be a separate, bigger decision (a
# real reporting/telemetry mechanism) that hasn't been made here.
set -euo pipefail

REPO_DIR="$1"
LOG_FILE="${HOME}/.claude/neeve-copilot-sync.log"
SELECTION_RECEIPT="${HOME}/.claude/neeve-copilot-selection"

if [[ ! -d "${REPO_DIR}/.git" ]]; then
  exit 0
fi

BEFORE="$(git -C "${REPO_DIR}" rev-parse HEAD 2>/dev/null || echo "")"
BRANCH="$(git -C "${REPO_DIR}" branch --show-current 2>/dev/null || echo "")"

if [[ -z "${BEFORE}" || -z "${BRANCH}" ]]; then
  exit 0
fi

PULL_OK=true
if ! git -C "${REPO_DIR}" pull --quiet origin "${BRANCH}" 2>/dev/null; then
  # Offline, no network, or a local change blocking a fast-forward — never
  # block session start over this; just log it and move on.
  PULL_OK=false
fi

AFTER="$(git -C "${REPO_DIR}" rev-parse HEAD 2>/dev/null || echo "${BEFORE}")"
USER_ID="$(git -C "${REPO_DIR}" config user.email 2>/dev/null || whoami)"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
UPDATED=false
INSTALL_OK=true

if [[ -n "${AFTER}" && "${BEFORE}" != "${AFTER}" ]]; then
  UPDATED=true

  INSTALL_FLAGS=""
  if [[ -s "${SELECTION_RECEIPT}" ]]; then
    INSTALL_FLAGS="$(tr '\n' ' ' < "${SELECTION_RECEIPT}")"
  fi

  INSTALL_LOG="$(mktemp)"
  # shellcheck disable=SC2086  # INSTALL_FLAGS is a fixed, receipt-controlled list of literal flags
  if bash "${REPO_DIR}/neeve/install.sh" ${INSTALL_FLAGS} >"${INSTALL_LOG}" 2>&1; then
    echo "neeve-copilot updated (${BEFORE:0:7} -> ${AFTER:0:7}) and reinstalled."
  else
    INSTALL_OK=false
    echo "neeve-copilot updated (${BEFORE:0:7} -> ${AFTER:0:7}) but the reinstall FAILED:" >&2
    sed 's/^/  /' "${INSTALL_LOG}" >&2
  fi
  rm -f "${INSTALL_LOG}"
fi

mkdir -p "$(dirname "${LOG_FILE}")"
echo "${TIMESTAMP} user=${USER_ID} branch=${BRANCH} before=${BEFORE:0:7} after=${AFTER:0:7} pulled=${PULL_OK} updated=${UPDATED} install_ok=${INSTALL_OK}" >> "${LOG_FILE}"
