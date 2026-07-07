#!/usr/bin/env bash
# =============================================================================
# Neeve Engineering Skills — Universal Installer
# Works on macOS (bash 3.2+), Linux, and Windows (Git Bash / WSL)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Auto-discovered from skills-src/ (mirrors skills_sync.sh's own discover_skills()
# and the agents-src discovery loop below) — a hardcoded list here previously let
# ot-building-automation silently never get installed after it was added to
# skills-src/ without this list being updated. Never hardcode this again.
SKILLS=""
for skill_dir in "${SCRIPT_DIR}"/skills-src/*/; do
  [[ -f "${skill_dir}SKILL.md" ]] || continue
  SKILLS="${SKILLS} $(basename "${skill_dir}")"
done
SKILLS="${SKILLS# }"
ZIP_DIR="${SKILLS_ZIP_DIR:-}"
SYNC_SCRIPT="${SCRIPT_DIR}/scripts/skills_sync.sh"
RENDER_SCRIPT="${SCRIPT_DIR}/scripts/context_render.py"
MERGE_SCRIPT="${SCRIPT_DIR}/scripts/merge_house_rules.py"
AGENTS_RENDER_SCRIPT="${SCRIPT_DIR}/scripts/agents_render.py"
AGENTS_SRC_DIR="${SCRIPT_DIR}/agents-src"
SESSION_HOOK_MERGE_SCRIPT="${SCRIPT_DIR}/scripts/merge_session_hook.py"
REFRESH_CONTEXT_SCRIPT="${SCRIPT_DIR}/hooks-src/refresh-context.sh"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

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

usage() {
  cat <<EOF
Usage: bash install.sh [OPTIONS]

Everything installs to your machine only — global, user-level, never
project-scoped. Nothing is ever committed into a product repo; neeve-copilot
is the single centralized source, refreshed by re-running this script.

Options:
  --all              Install for all supported agents (global scope)
  --claude-code      Claude Code + VS Code (Claude extension)
  --codex            OpenAI Codex CLI
  --antigravity      Google Antigravity
  --copilot          GitHub Copilot (global user scope)
  --cursor           Cursor IDE (prints a one-time manual paste step)
  --help             Show this help

Examples:
  bash install.sh                              # auto-detect installed agents
  bash install.sh --all                        # install for every agent
  bash install.sh --claude-code --cursor       # specific agents only
EOF
}

# ── Parse args ────────────────────────────────────────────────────────────────
INSTALL_ALL=false
DO_CLAUDE=false
DO_CODEX=false
DO_ANTIGRAVITY=false
DO_COPILOT=false
DO_CURSOR=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)          INSTALL_ALL=true ;;
    --claude-code)  DO_CLAUDE=true ;;
    --codex)        DO_CODEX=true ;;
    --antigravity)  DO_ANTIGRAVITY=true ;;
    --copilot)      DO_COPILOT=true ;;
    --cursor)       DO_CURSOR=true ;;
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

# ── House rules: global, user-level, every workspace on this machine ────────
# The shared culture/ethos/principles/quality-gates/product-overview content
# (context-src/base.md, minus anything repo-specific) installs once per
# engineer, into each tool's own user-level instructions location. Nothing is
# ever written into a product repo — re-run this installer to refresh it
# after context-src/base.md changes.
if [[ -f "${RENDER_SCRIPT}" ]]; then
  HOUSE_RULES_TMP="$(mktemp)"
  trap 'rm -f "${HOUSE_RULES_TMP}"' EXIT
  if python3 "${RENDER_SCRIPT}" --house-rules "${HOUSE_RULES_TMP}" >/dev/null; then
    hdr "House rules (global, every workspace)"

    if $DO_CLAUDE; then
      python3 "${MERGE_SCRIPT}" "${HOME}/.claude/CLAUDE.md" "${HOUSE_RULES_TMP}" >/dev/null
      ok "Claude Code  →  ~/.claude/CLAUDE.md"
    fi

    if $DO_CODEX; then
      python3 "${MERGE_SCRIPT}" "${HOME}/.codex/AGENTS.md" "${HOUSE_RULES_TMP}" >/dev/null
      ok "Codex CLI  →  ~/.codex/AGENTS.md"
    fi

    if $DO_COPILOT; then
      mkdir -p "${HOME}/.copilot/instructions"
      {
        echo "---"
        echo 'applyTo: "**"'
        echo "---"
        echo ""
        cat "${HOUSE_RULES_TMP}"
      } > "${HOME}/.copilot/instructions/neeve-house-rules.instructions.md"
      ok "GitHub Copilot  →  ~/.copilot/instructions/neeve-house-rules.instructions.md"
    fi

    if $DO_ANTIGRAVITY; then
      warn "Antigravity: no confirmed global-instructions file location yet — skipped. Flag to Neeve tooling if you know it."
    fi

    if $DO_CURSOR; then
      warn "Cursor stores global rules in Settings > Rules > User Rules (not a plain file on disk),"
      warn "so this can't be written automatically. One-time manual step:"
      warn "  1. Open Cursor → Cmd/Ctrl+Shift+P → \"Rules: User Rules\""
      warn "  2. Paste the contents of: ${HOUSE_RULES_TMP}"
      warn "  (that temp file is deleted when this script exits — copy it now if needed:"
      warn "   cat ${HOUSE_RULES_TMP} | pbcopy    # macOS clipboard)"
    fi
  else
    err "context_render.py --house-rules failed — skipping house-rules install"
  fi
else
  warn "No scripts/context_render.py found — skipping house-rules install (skills-only mode)"
fi

# ── Agents: cross-tool, rendered from agents-src/ ────────────────────────────
# Claude Code, Copilot (VS Code), and Codex CLI each have a real, working,
# global custom-agent mechanism — in three incompatible formats. Cursor and
# Antigravity have none, so they get the same content as a Skill instead
# (skills auto-trigger on phrasing, so this isn't a downgrade). One source
# per agent (agents-src/<name>/AGENT.md), rendered per tool — see
# agents-src/README.md.
if [[ -f "${AGENTS_RENDER_SCRIPT}" && -d "${AGENTS_SRC_DIR}" ]]; then
  AGENT_NAMES=()
  for agent_dir in "${AGENTS_SRC_DIR}"/*/; do
    [[ -f "${agent_dir}AGENT.md" ]] || continue
    AGENT_NAMES+=("$(basename "${agent_dir}")")
  done

  if [[ ${#AGENT_NAMES[@]} -gt 0 ]]; then
    hdr "Agents (cross-tool, rendered from agents-src/)"
    for agent in "${AGENT_NAMES[@]}"; do
      if $DO_CLAUDE; then
        if python3 "${AGENTS_RENDER_SCRIPT}" "${agent}" --claude "${HOME}/.claude/agents/${agent}.md" >/dev/null; then
          ok "Claude Code  →  ~/.claude/agents/${agent}.md"
        else
          err "Claude Code agent render failed: ${agent}"
        fi
      fi
      if $DO_COPILOT; then
        if python3 "${AGENTS_RENDER_SCRIPT}" "${agent}" --copilot "${HOME}/.copilot/agents/${agent}.agent.md" >/dev/null; then
          ok "GitHub Copilot  →  ~/.copilot/agents/${agent}.agent.md"
        else
          err "Copilot agent render failed: ${agent}"
        fi
      fi
      if $DO_CODEX; then
        if python3 "${AGENTS_RENDER_SCRIPT}" "${agent}" --codex "${HOME}/.codex/agents/${agent}.toml" >/dev/null; then
          ok "Codex CLI  →  ~/.codex/agents/${agent}.toml"
        else
          err "Codex agent render failed: ${agent}"
        fi
      fi
      if $DO_CURSOR; then
        if python3 "${AGENTS_RENDER_SCRIPT}" "${agent}" --skill-fallback "$(global_path cursor)" >/dev/null; then
          ok "Cursor (skill fallback, no native agent concept)  →  $(global_path cursor)/${agent}/"
        else
          err "Cursor skill-fallback render failed: ${agent}"
        fi
      fi
      if $DO_ANTIGRAVITY; then
        if python3 "${AGENTS_RENDER_SCRIPT}" "${agent}" --skill-fallback "$(global_path antigravity)" >/dev/null; then
          ok "Antigravity (skill fallback, no native agent concept)  →  $(global_path antigravity)/${agent}/"
        else
          err "Antigravity skill-fallback render failed: ${agent}"
        fi
      fi
    done
  fi
else
  warn "No scripts/agents_render.py or agents-src/ found — skipping agent install"
fi

# ── Freshness: global Claude Code SessionStart hook ──────────────────────────
# Every engineer has their own local clone of neeve-copilot — a single
# canonical context-src/repos/*.yaml only produces consistent answers across
# engineers if everyone's clone is actually current, not just "current as of
# whoever's last sync_skills.sh run." Claude Code supports a real global
# SessionStart hook (~/.claude/settings.json) that can pull this repo and
# reinstall automatically, quietly, only on days something actually changed —
# confirmed via Claude Code's own docs, not assumed. No equivalent confirmed
# for Copilot/Cursor/Codex/Antigravity yet — this is Claude-Code-only today,
# stated plainly rather than implied to work everywhere.
if $DO_CLAUDE && [[ -f "${SESSION_HOOK_MERGE_SCRIPT}" && -f "${REFRESH_CONTEXT_SCRIPT}" ]]; then
  hdr "Freshness (Claude Code global SessionStart hook)"
  HOOK_COMMAND="bash ${REFRESH_CONTEXT_SCRIPT} ${REPO_ROOT}"
  if python3 "${SESSION_HOOK_MERGE_SCRIPT}" "${HOME}/.claude/settings.json" "${HOOK_COMMAND}" "refresh-context.sh" >/dev/null; then
    ok "Claude Code  →  ~/.claude/settings.json (SessionStart hook, quiet no-op unless neeve-copilot has updates)"
  else
    err "Failed to install the SessionStart freshness hook — ~/.claude/settings.json left untouched"
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
echo "Invoke manually (${SKILLS// /, }):"
echo "  /<skill-name>   (Claude Code / Copilot / Cursor / Antigravity)"
echo "  \$<skill-name>   (Codex)"
echo ""
echo "Agents (to-prd, to-erd, repo-guide) — invocation differs by tool:"
echo "  Claude Code:      auto-triggers on phrasing, or @agent-<name>"
echo "  Copilot (VS Code): pick from the agent picker (not auto-triggered by default)"
echo "  Codex CLI:         /agent  (explicit only, does not auto-trigger)"
echo "  Cursor/Antigravity: same as a skill — auto-triggers on phrasing"
