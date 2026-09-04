#!/usr/bin/env bash
# End-to-end regression test for the SessionStart refresh loop's scope
# (issue #19): a refresh must reinstall only the tool(s) the engineer
# actually selected at install time, do exactly one git pull, and surface
# (not swallow) a reinstall failure without blocking session start.
#
# Builds two clones of THIS repo against a local bare "upstream" so the test
# never touches the real GitHub remote: one plays the role of whoever pushed
# the change, the other plays the role of the engineer's machine that the
# hook runs against.
#
# Run: bash neeve/scripts/test_refresh_scope.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
FAILURES=0
ok()  { echo -e "  ${GREEN}✓${NC} $*"; }
fail(){ echo -e "  ${RED}✗${NC} $*"; FAILURES=$((FAILURES + 1)); }

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

BARE="${WORK}/upstream.git"
UP="${WORK}/up"
ENG="${WORK}/eng"
TEST_BRANCH="refresh-scope-test"

git init --bare -q "${BARE}" 2>/dev/null
git clone -q "${REPO_ROOT}" "${UP}" 2>/dev/null
git -C "${UP}" config user.email "refresh-scope-test@neeve.local"
git -C "${UP}" config user.name "Refresh Scope Test"
git -C "${UP}" checkout -q -b "${TEST_BRANCH}"
git -C "${UP}" remote set-url origin "${BARE}"
git -C "${UP}" push -q origin "${TEST_BRANCH}"

git clone -q "${BARE}" "${ENG}"
git -C "${ENG}" checkout -q "${TEST_BRANCH}"

export HOME="${WORK}/home"
mkdir -p "${HOME}"

echo "── install.sh --claude-code writes a receipt scoped to that one tool ──"
bash "${ENG}/neeve/install.sh" --claude-code >/dev/null 2>&1
RECEIPT="${HOME}/.claude/neeve-copilot-selection"
if [[ "$(cat "${RECEIPT}" 2>/dev/null)" == "--claude-code" ]]; then
  ok "receipt contains exactly --claude-code"
else
  fail "receipt was [$(cat "${RECEIPT}" 2>/dev/null || echo MISSING)], expected --claude-code"
fi

echo "── a refresh after an upstream change replays only that tool ──"
echo "change" > "${UP}/refresh-scope-test-marker.txt"
git -C "${UP}" add refresh-scope-test-marker.txt
git -C "${UP}" commit -q -m "test: trigger a refresh"
git -C "${UP}" push -q origin "${TEST_BRANCH}"

bash "${ENG}/neeve/hooks/refresh-context.sh" "${ENG}"
LOG_LINE="$(tail -n 1 "${HOME}/.claude/neeve-copilot-sync.log")"

if [[ "${LOG_LINE}" == *"pulled=true"* && "${LOG_LINE}" == *"updated=true"* && "${LOG_LINE}" == *"install_ok=true"* ]]; then
  ok "log reports a single successful pull + reinstall: ${LOG_LINE}"
else
  fail "unexpected log line: ${LOG_LINE}"
fi

OTHER_DIRS_CLEAN=true
for other in .codex .cursor .gemini .copilot; do
  if [[ -e "${HOME}/${other}" ]]; then
    fail "refresh created ${HOME}/${other} — only --claude-code was ever selected"
    OTHER_DIRS_CLEAN=false
  fi
done
$OTHER_DIRS_CLEAN && ok "no other tool directories were created"

echo "── a broken reinstall is surfaced, never blocks the hook ──"
echo "--bogus-flag" > "${RECEIPT}"
echo "change 2" >> "${UP}/refresh-scope-test-marker.txt"
git -C "${UP}" add refresh-scope-test-marker.txt
git -C "${UP}" commit -q -m "test: trigger a failing refresh"
git -C "${UP}" push -q origin "${TEST_BRANCH}"

HOOK_STDERR="${WORK}/hook_stderr.log"
if bash "${ENG}/neeve/hooks/refresh-context.sh" "${ENG}" 2>"${HOOK_STDERR}"; then
  ok "hook still exits 0 when the reinstall fails"
else
  fail "hook exited non-zero on a reinstall failure — must never block session start"
fi

if grep -q "FAILED" "${HOOK_STDERR}"; then
  ok "reinstall failure was surfaced on stderr"
else
  fail "reinstall failure was not surfaced: $(cat "${HOOK_STDERR}")"
fi

LOG_LINE2="$(tail -n 1 "${HOME}/.claude/neeve-copilot-sync.log")"
if [[ "${LOG_LINE2}" == *"install_ok=false"* ]]; then
  ok "log records install_ok=false for the failed reinstall"
else
  fail "log did not record the reinstall failure: ${LOG_LINE2}"
fi

echo ""
if [[ ${FAILURES} -eq 0 ]]; then
  echo -e "${GREEN}All refresh-scope checks passed.${NC}"
  exit 0
else
  echo -e "${RED}${FAILURES} refresh-scope check(s) failed.${NC}"
  exit 1
fi
