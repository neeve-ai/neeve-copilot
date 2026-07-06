#!/usr/bin/env bash
# =============================================================================
# Neeve Engineering Skills — Universal Installer
# Works on macOS (bash 3.2+), Linux, and Windows (Git Bash / WSL)
# =============================================================================
set -euo pipefail

SKILLS="code-review to-spec implement-spec neeve-dls repo-intel repo-ask"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZIP_DIR="${SKILLS_ZIP_DIR:-}"
SYNC_SCRIPT="${SCRIPT_DIR}/scripts/skills_sync.sh"
PROMPTS_SRC_DIR="${SCRIPT_DIR}/prompts-src"
HOOKS_SRC_DIR="${SCRIPT_DIR}/hooks-src"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()  { echo -e "  ${GREEN}✓${NC} $*"; }
warn(){ echo -e "  ${YELLOW}⚠${NC} $*"; }
err() { echo -e "  ${RED}✗${NC} $*"; }
hdr() { echo -e "\n${CYAN}── $* ──${NC}"; }

# ── Agent paths ───────────────────────────────────────────────────────────────
# Returns the global skills dir for a given agent name
global_path() {
  case "$1" in
    claude-code)  echo "${HOME}/.claude/skills" ;;
    codex)        echo "${HOME}/.codex/skills" ;;
    antigravity)  echo "${HOME}/.gemini/antigravity/skills" ;;
    copilot)      echo "${HOME}/.copilot/skills" ;;
    cursor)       echo "${HOME}/.cursor/skills" ;;
  esac
}

# Returns the project-relative skills dir for a given agent name
project_rel_path() {
  case "$1" in
    claude-code)  echo ".claude/skills" ;;
    codex)        echo ".agents/skills" ;;
    antigravity)  echo ".agents/skills" ;;
    copilot)      echo ".github/skills" ;;
    cursor)       echo ".cursor/skills" ;;
  esac
}

usage() {
  cat <<EOF
Usage: bash install.sh [OPTIONS]

Options:
  --all              Install for all supported agents (global scope)
  --claude-code      Claude Code + VS Code (Claude extension)
  --codex            OpenAI Codex CLI
  --antigravity      Google Antigravity
  --copilot          GitHub Copilot (global user scope)
  --cursor           Cursor IDE (global user scope)
  --project PATH     Also install project-scoped copies into PATH
  --help             Show this help

Examples:
  bash install.sh                              # auto-detect installed agents
  bash install.sh --all                        # install for every agent
  bash install.sh --claude-code --cursor       # specific agents only
  bash install.sh --all --project ~/robin-ai   # global + project-scoped
EOF
}

# ── Parse args ────────────────────────────────────────────────────────────────
INSTALL_ALL=false
DO_CLAUDE=false
DO_CODEX=false
DO_ANTIGRAVITY=false
DO_COPILOT=false
DO_CURSOR=false
PROJECT_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)          INSTALL_ALL=true ;;
    --claude-code)  DO_CLAUDE=true ;;
    --codex)        DO_CODEX=true ;;
    --antigravity)  DO_ANTIGRAVITY=true ;;
    --copilot)      DO_COPILOT=true ;;
    --cursor)       DO_CURSOR=true ;;
    --project)      shift; PROJECT_ROOT="${1:-}" ;;
    --help|-h)      usage; exit 0 ;;
    *) warn "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done

if $INSTALL_ALL; then
  DO_CLAUDE=true; DO_CODEX=true; DO_ANTIGRAVITY=true; DO_COPILOT=true; DO_CURSOR=true
fi

# ── Auto-detect if nothing specified ─────────────────────────────────────────
if ! $DO_CLAUDE && ! $DO_CODEX && ! $DO_ANTIGRAVITY && ! $DO_COPILOT && ! $DO_CURSOR; then
  echo "No agent specified — auto-detecting..."
  command -v claude      &>/dev/null && { DO_CLAUDE=true;      echo "  found: Claude Code"; }
  command -v codex       &>/dev/null && { DO_CODEX=true;       echo "  found: Codex CLI"; }
  [[ -d "${HOME}/.gemini/antigravity" ]] && { DO_ANTIGRAVITY=true; echo "  found: Antigravity"; }
  [[ -d "${HOME}/.copilot" ]]            && { DO_COPILOT=true;     echo "  found: GitHub Copilot"; }
  [[ -d "${HOME}/.cursor"  ]]            && { DO_CURSOR=true;      echo "  found: Cursor"; }

  if ! $DO_CLAUDE && ! $DO_CODEX && ! $DO_ANTIGRAVITY && ! $DO_COPILOT && ! $DO_CURSOR; then
    warn "No agents detected. Try: bash install.sh --claude-code"
    warn "or:                      bash install.sh --all"
    exit 1
  fi
fi

ensure_skill_packages() {
  if [[ -z "${ZIP_DIR}" ]]; then
    if [[ -d "${SCRIPT_DIR}/zips" ]]; then
      ZIP_DIR="${SCRIPT_DIR}/zips"
    elif [[ -d "${SCRIPT_DIR}/dist/zips" ]]; then
      ZIP_DIR="${SCRIPT_DIR}/dist/zips"
    else
      ZIP_DIR="${SCRIPT_DIR}/dist/zips"
    fi
  fi

  # Prefer a fresh rebuild from skills-src so source edits always propagate.
  # (Reusing pre-built zips silently installs stale skills when sources change.)
  if [[ -d "${SCRIPT_DIR}/skills-src" && -f "${SYNC_SCRIPT}" ]]; then
    mkdir -p "${ZIP_DIR}"
    warn "Rebuilding skill packages from local skills-src into ${ZIP_DIR}"
    SKILLS_ZIP_DIR="${ZIP_DIR}" bash "${SYNC_SCRIPT}" pack
  else
    # No local sources — fall back to whatever zips were shipped in the bundle.
    local missing=0 skill zip
    for skill in $SKILLS; do
      zip="${ZIP_DIR}/${skill}.zip"
      [[ -f "${zip}" ]] || missing=$((missing + 1))
    done
    if [[ "${missing}" -gt 0 ]]; then
      err "Skill packages are missing and no local skills-src packer is available."
      err "Download the GitHub release bundle or clone the full repository checkout."
      exit 1
    fi
  fi

  hdr "Verifying skill packages"
  missing=0
  for skill in $SKILLS; do
    zip="${ZIP_DIR}/${skill}.zip"
    if [[ -f "$zip" ]]; then
      size=$(du -h "$zip" | cut -f1)
      ok "${skill}.zip (${size})"
    else
      err "${skill}.zip not found in ${ZIP_DIR}/"
      missing=$((missing + 1))
    fi
  done
  if [[ $missing -gt 0 ]]; then
    echo ""
    err "Unable to prepare the required zip files in: ${ZIP_DIR}/"
    exit 1
  fi
}

ensure_skill_packages

# ── Install one skill into one directory ─────────────────────────────────────
install_to() {
  local skill="$1" dest_dir="$2"
  local zip="${ZIP_DIR}/${skill}.zip"
  local target="${dest_dir}/${skill}"

  mkdir -p "${dest_dir}"
  [[ -d "${target}" ]] && rm -rf "${target}"
  unzip -q "${zip}" -d "${dest_dir}"

  if [[ ! -f "${target}/SKILL.md" ]]; then
    err "SKILL.md not found at ${target}/ — check zip structure"
    return 1
  fi
  return 0
}

# ── Install for each selected agent ──────────────────────────────────────────
TOTAL_OK=0
TOTAL_FAIL=0

install_agent() {
  local agent="$1"
  local dest
  dest="$(global_path "$agent")"
  hdr "${agent}  →  ${dest}"
  for skill in $SKILLS; do
    if install_to "${skill}" "${dest}"; then
      ok "${skill}"
      TOTAL_OK=$((TOTAL_OK + 1))
    else
      err "${skill}"
      TOTAL_FAIL=$((TOTAL_FAIL + 1))
    fi
  done
}

$DO_CLAUDE      && install_agent "claude-code"
$DO_CODEX       && install_agent "codex"
$DO_ANTIGRAVITY && install_agent "antigravity"
$DO_COPILOT     && install_agent "copilot"
$DO_CURSOR      && install_agent "cursor"

# ── Project-scoped install ────────────────────────────────────────────────────
if [[ -n "$PROJECT_ROOT" ]]; then
  if [[ ! -d "$PROJECT_ROOT" ]]; then
    err "Project path not found: ${PROJECT_ROOT}"
  else
    # Track which relative paths we've already written (codex + antigravity share .agents/skills)
    done_paths=""
    install_project_agent() {
      local agent="$1"
      local rel
      rel="$(project_rel_path "$agent")"
      local abs="${PROJECT_ROOT}/${rel}"
      # Skip if we already installed to this path
      if echo "$done_paths" | grep -qF "|${rel}|"; then
        return
      fi
      done_paths="${done_paths}|${rel}|"
      hdr "project  →  ${abs}"
      for skill in $SKILLS; do
        if install_to "${skill}" "${abs}"; then
          ok "${skill}  (${rel})"
          TOTAL_OK=$((TOTAL_OK + 1))
        else
          err "${skill}"
          TOTAL_FAIL=$((TOTAL_FAIL + 1))
        fi
      done
    }

    $DO_CLAUDE      && install_project_agent "claude-code"
    $DO_CODEX       && install_project_agent "codex"
    $DO_ANTIGRAVITY && install_project_agent "antigravity"
    $DO_COPILOT     && install_project_agent "copilot"
    $DO_CURSOR      && install_project_agent "cursor"

    # Prompts and hooks are Copilot/VS Code-specific project artifacts (no
    # global-scope equivalent), so they're only written when Copilot is selected.
    if $DO_COPILOT; then
      hdr "project  →  ${PROJECT_ROOT}/.github/prompts"
      if [[ -d "${PROMPTS_SRC_DIR}" ]]; then
        mkdir -p "${PROJECT_ROOT}/.github/prompts"
        cp "${PROMPTS_SRC_DIR}"/*.prompt.md "${PROJECT_ROOT}/.github/prompts/"
        ok "6 prompt files"
      else
        warn "No prompts-src/ found — skipping prompt file install"
      fi

      hdr "project  →  ${PROJECT_ROOT}/.github/hooks"
      if [[ -f "${HOOKS_SRC_DIR}/baseline.hooks.json" ]]; then
        mkdir -p "${PROJECT_ROOT}/.github/hooks/scripts"
        cp "${HOOKS_SRC_DIR}/baseline.hooks.json" "${PROJECT_ROOT}/.github/hooks/hooks.json"
        cp "${HOOKS_SRC_DIR}/scripts/"*.sh "${PROJECT_ROOT}/.github/hooks/scripts/"
        chmod +x "${PROJECT_ROOT}/.github/hooks/scripts/"*.sh
        ok "hooks.json + $(ls "${HOOKS_SRC_DIR}/scripts" | wc -l | tr -d ' ') hook scripts"
      else
        warn "No hooks-src/baseline.hooks.json found — skipping hooks install"
      fi
    fi

    echo ""
    warn "Commit project-scoped skills so your team gets them on git clone:"
    echo "       cd ${PROJECT_ROOT}"
    echo "       git add .claude/skills/ .github/skills/ .agents/skills/ .cursor/skills/"
    echo "       git add .github/prompts/ .github/hooks/"
    echo "       git commit -m 'chore: add Neeve engineering skills, prompts, and hooks'"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
ok "${TOTAL_OK} installs succeeded"
[[ $TOTAL_FAIL -gt 0 ]] && err "${TOTAL_FAIL} installs failed"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Verify in your agent:"
echo "  Claude Code / VS Code:  /skills"
echo "  Codex CLI:              \$skills"
echo "  Cursor:                 /skills  (chat panel)"
echo "  Copilot (VS Code):      /skills  (Copilot chat)"
echo "  Antigravity:            @skills"
echo ""
echo "Invoke manually:"
echo "  /code-review  |  /to-spec  |  /implement-spec  |  /neeve-dls"
echo "  \$code-review  |  \$to-spec  |  \$implement-spec  |  \$neeve-dls  (Codex)"
