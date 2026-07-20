#!/usr/bin/env bash
# Runs as a global Claude Code SessionStart hook (installed via
# merge_session_hook.py). Keeps house rules, skills, and the cross-tool
# agents current on this machine without relying on anyone
# remembering to re-run sync_skills.sh — the freshness problem a single
# canonical source doesn't solve by itself (every engineer has their own
# local clone, which is only as fresh as their last pull).
#
# Deliberately a no-op on any day nothing changed upstream: pulls, compares
# HEAD before/after, and only re-runs sync_skills.sh (which reinstalls
# skills/agents/house rules) if the pull actually moved HEAD. This keeps a
# normal session start fast and quiet — no rebuild, no noise — while still
# closing the loop automatically the day something did change.
#
# Every run (not just ones that update something) appends one line to a
# local, per-engineer log — user + commit hash, so "what commit is this
# machine actually on, and when did it last check" is a real, inspectable
# fact instead of a guess. This log is local only: it is never pushed,
# uploaded, or aggregated anywhere by this script — that would be a
# separate, bigger decision (a real reporting/telemetry mechanism) that
# hasn't been made here.
set -euo pipefail

REPO_DIR="$1"
LOG_FILE="${HOME}/.claude/neeve-copilot-sync.log"

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

if [[ -n "${AFTER}" && "${BEFORE}" != "${AFTER}" ]]; then
  bash "${REPO_DIR}/sync_skills.sh" >/dev/null 2>&1 || true
  UPDATED=true
  echo "neeve-copilot updated (${BEFORE:0:7} -> ${AFTER:0:7}) and reinstalled."
fi

mkdir -p "$(dirname "${LOG_FILE}")"
echo "${TIMESTAMP} user=${USER_ID} branch=${BRANCH} before=${BEFORE:0:7} after=${AFTER:0:7} pulled=${PULL_OK} updated=${UPDATED}" >> "${LOG_FILE}"
