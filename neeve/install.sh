#!/usr/bin/env bash
# =============================================================================
# Neeve Engineering Skills — Universal Installer
# Works on macOS (bash 3.2+), Linux, and Windows (Git Bash / WSL)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Auto-discovered from both skill roots — org-level skills/ plus every
# product's skills/ (mirrors skills_sync.sh's own discover_skills() and
# the agent discovery loop below) — a hardcoded list here previously let
# ot-building-automation silently never get installed after it was added to
# skills/ without this list being updated. Never hardcode this again.
SKILLS=""
for skills_root in "${SCRIPT_DIR}/skills" "${SCRIPT_DIR}"/products/*/skills; do
  [[ -d "${skills_root}" ]] || continue
  for skill_dir in "${skills_root}"/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    SKILLS="${SKILLS} $(basename "${skill_dir}")"
  done
done
SKILLS="${SKILLS# }"
ZIP_DIR="${SKILLS_ZIP_DIR:-}"
SYNC_SCRIPT="${SCRIPT_DIR}/scripts/skills_sync.sh"
RENDER_SCRIPT="${SCRIPT_DIR}/scripts/context_render.py"
MERGE_SCRIPT="${SCRIPT_DIR}/scripts/merge_house_rules.py"
AGENTS_RENDER_SCRIPT="${SCRIPT_DIR}/scripts/agents_render.py"
AGENTS_SRC_DIR="${SCRIPT_DIR}/agent"
SESSION_HOOK_MERGE_SCRIPT="${SCRIPT_DIR}/scripts/merge_session_hook.py"
REFRESH_CONTEXT_SCRIPT="${SCRIPT_DIR}/hooks/refresh-context.sh"
MERGE_DEFAULT_AGENT_SCRIPT="${SCRIPT_DIR}/scripts/merge_default_agent.py"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

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
    antigravity)  echo "${HOME}/.gemini/config/skills" ;;
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
  { command -v antigravity &>/dev/null || [[ -d "${HOME}/.gemini" ]]; } && { DO_ANTIGRAVITY=true; echo "  found: Antigravity"; }
  [[ -d "${HOME}/.copilot" ]]            && { DO_COPILOT=true;     echo "  found: GitHub Copilot"; }
  [[ -d "${HOME}/.cursor"  ]]            && { DO_CURSOR=true;      echo "  found: Cursor"; }

  if ! $DO_CLAUDE && ! $DO_CODEX && ! $DO_ANTIGRAVITY && ! $DO_COPILOT && ! $DO_CURSOR; then
    warn "No agents detected. Try: bash install.sh --claude-code"
    warn "or:                      bash install.sh --all"
    exit 1
  fi
fi

# ── Selection receipt ────────────────────────────────────────────────────────
# Records exactly which agent flags this run resolved to (explicit or
# auto-detected) so a later, unattended refresh (the SessionStart hook) can
# replay the same selection instead of guessing --all and installing into
# every tool regardless of what the engineer actually chose.
SELECTION_RECEIPT="${HOME}/.claude/neeve-copilot-selection"
write_selection_receipt() {
  mkdir -p "$(dirname "${SELECTION_RECEIPT}")"
  : > "${SELECTION_RECEIPT}"
  if $DO_CLAUDE;      then echo "--claude-code" >> "${SELECTION_RECEIPT}"; fi
  if $DO_CODEX;       then echo "--codex"       >> "${SELECTION_RECEIPT}"; fi
  if $DO_ANTIGRAVITY; then echo "--antigravity" >> "${SELECTION_RECEIPT}"; fi
  if $DO_COPILOT;     then echo "--copilot"     >> "${SELECTION_RECEIPT}"; fi
  if $DO_CURSOR;      then echo "--cursor"      >> "${SELECTION_RECEIPT}"; fi
}
write_selection_receipt

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

  # Prefer a fresh rebuild from skills so source edits always propagate.
  # (Reusing pre-built zips silently installs stale skills when sources change.)
  if [[ -d "${SCRIPT_DIR}/skills" && -f "${SYNC_SCRIPT}" ]]; then
    mkdir -p "${ZIP_DIR}"
    warn "Rebuilding skill packages from local skills into ${ZIP_DIR}"
    SKILLS_ZIP_DIR="${ZIP_DIR}" bash "${SYNC_SCRIPT}" pack
  else
    # No local sources — fall back to whatever zips were shipped in the bundle.
    local missing=0 skill zip
    for skill in $SKILLS; do
      zip="${ZIP_DIR}/${skill}.zip"
      [[ -f "${zip}" ]] || missing=$((missing + 1))
    done
    if [[ "${missing}" -gt 0 ]]; then
      err "Skill packages are missing and no local skills packer is available."
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

# Every run is a reset to exactly the current skills, not an additive
# overlay: a manifest file records which skill names neeve-copilot installed
# into this directory last run, so a skill that's renamed or removed from
# skills gets its old, now-orphaned directory removed too — instead of
# silently surviving forever like a stale skill would with the old
# install-only-what's-currently-listed behavior. This never touches a
# directory not in *our own* manifest, so a third-party skill some other tool
# put in the same shared folder is never at risk.
MANIFEST_NAME=".neeve-manifest"

prune_stale_skills() {
  local dest_dir="$1"
  local manifest="${dest_dir}/${MANIFEST_NAME}"
  [[ -f "${manifest}" ]] || return 0

  local previously_installed name
  previously_installed="$(cat "${manifest}")"
  for name in ${previously_installed}; do
    if ! printf '%s\n' ${SKILLS} | grep -qx "${name}"; then
      if [[ -d "${dest_dir}/${name}" ]]; then
        rm -rf "${dest_dir}/${name}"
        ok "Removed stale skill (no longer in skills): ${name}"
      fi
    fi
  done
}

write_skills_manifest() {
  local dest_dir="$1"
  printf '%s\n' ${SKILLS} > "${dest_dir}/${MANIFEST_NAME}"
}

install_agent() {
  local agent="$1"
  local dest
  dest="$(global_path "$agent")"
  hdr "${agent}  →  ${dest}"
  mkdir -p "${dest}"
  prune_stale_skills "${dest}"
  for skill in $SKILLS; do
    if install_to "${skill}" "${dest}"; then
      ok "${skill}"
      TOTAL_OK=$((TOTAL_OK + 1))
    else
      err "${skill}"
      TOTAL_FAIL=$((TOTAL_FAIL + 1))
    fi
  done
  write_skills_manifest "${dest}"
}

$DO_CLAUDE      && install_agent "claude-code"
$DO_CODEX       && install_agent "codex"
$DO_ANTIGRAVITY && install_agent "antigravity"
$DO_COPILOT     && install_agent "copilot"
$DO_CURSOR      && install_agent "cursor"

# ── House rules: global, user-level, every workspace on this machine ────────
# The shared culture/ethos/principles/quality-gates/product-overview content
# (context/base.md, minus anything repo-specific) installs once per
# engineer, into each tool's own user-level instructions location. Nothing is
# ever written into a product repo — re-run this installer to refresh it
# after context/base.md changes.
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
      python3 "${MERGE_SCRIPT}" "${HOME}/.gemini/AGENTS.md" "${HOUSE_RULES_TMP}" >/dev/null
      ok "Antigravity  →  ~/.gemini/AGENTS.md (cross-tool global rules; Antigravity-only overrides live in ~/.gemini/GEMINI.md, untouched by this installer)"
    fi

    if $DO_CURSOR; then
      # Cursor's GLOBAL User Rules are not a reliably writable plain file:
      # its own community forum confirms they live in an internal state DB
      # (state.vscdb) / cloud, and a third-party-blogged ~/.cursor/rules/*.mdc
      # global path is contested and unverified against Cursor's own docs. So
      # we do NOT auto-write it (writing to an unverified path silently does
      # nothing). Instead: persist the rules to a stable file the engineer can
      # re-open anytime, and auto-copy them to the clipboard so the one manual
      # paste is a single Cmd+V.
      CURSOR_RULES_FILE="${HOME}/.cursor/neeve-house-rules.md"
      mkdir -p "${HOME}/.cursor"
      cp "${HOUSE_RULES_TMP}" "${CURSOR_RULES_FILE}"
      COPIED=false
      if command -v pbcopy &>/dev/null; then
        pbcopy < "${CURSOR_RULES_FILE}" && COPIED=true
      elif command -v wl-copy &>/dev/null; then
        wl-copy < "${CURSOR_RULES_FILE}" && COPIED=true
      elif command -v xclip &>/dev/null; then
        xclip -selection clipboard < "${CURSOR_RULES_FILE}" && COPIED=true
      fi
      ok "Cursor  →  saved rules to ${CURSOR_RULES_FILE}"
      if $COPIED; then
        ok "Cursor  →  rules copied to clipboard — one-time paste: Cmd/Ctrl+Shift+P → \"Rules: Configure User Rules\" → Cmd/Ctrl+V"
      else
        warn "Cursor  →  couldn't auto-copy (no pbcopy/wl-copy/xclip). One-time paste:"
        warn "  Cmd/Ctrl+Shift+P → \"Rules: Configure User Rules\" → paste ${CURSOR_RULES_FILE}"
      fi
      warn "Cursor  →  GAP: no verified on-disk global-rules path, so this step stays manual."
      warn "           If your Cursor version DOES read ~/.cursor/rules/*.mdc for GLOBAL rules,"
      warn "           test it and tell the team — we can then auto-write it like the other tools."
    fi
  else
    err "context_render.py --house-rules failed — skipping house-rules install"
  fi
else
  warn "No scripts/context_render.py found — skipping house-rules install (skills-only mode)"
fi

# ── One-time cleanup: wrong Antigravity path from before this was verified ──
# Confirmed against Antigravity's own docs: global skills live in
# ~/.gemini/config/skills, not ~/.gemini/antigravity/skills. Nothing valid
# ever depended on the old path — it's dead, misplaced data, safe to remove.
if $DO_ANTIGRAVITY && [[ -d "${HOME}/.gemini/antigravity" ]]; then
  rm -rf "${HOME}/.gemini/antigravity"
  ok "Removed ~/.gemini/antigravity (wrong path from before the correct location was confirmed)"
fi

# ── Prune retired agents ──────────────────────────────────────────────────────
# `to-prd`/`to-erd`/`repo-guide`/`neeve-guide`/`neeve-reviewer`/
# `neeve-security-partner`/`neeve-pm-partner`/`neeve-design-partner` were
# retired in favor of the single `neeve` agent (their content folded into
# skills + neeve/references/*.md). Re-running install.sh only ever *writes*
# current agents — it never removed a retired one, so without this step a
# stale `~/.claude/agents/neeve-guide.md` etc. keeps auto-triggering forever
# on any machine that installed before this change. `to-prd`/`to-erd` are
# deliberately skipped for skill-fallback (Cursor/Antigravity): those names
# now legitimately belong to real skills installed at that same path.
RETIRED_AGENTS=(neeve-guide to-prd to-erd repo-guide neeve-reviewer neeve-security-partner neeve-pm-partner neeve-design-partner)
RETIRED_AGENTS_SKILL_FALLBACK_ONLY=(neeve-guide repo-guide neeve-reviewer neeve-security-partner neeve-pm-partner neeve-design-partner)
hdr "Pruning retired agents (superseded by the neeve agent)"
for name in "${RETIRED_AGENTS[@]}"; do
  if $DO_CLAUDE && [[ -f "${HOME}/.claude/agents/${name}.md" ]]; then
    rm -f "${HOME}/.claude/agents/${name}.md" && ok "Removed stale Claude Code agent: ${name}"
  fi
  if $DO_COPILOT && [[ -f "${HOME}/.copilot/agents/${name}.agent.md" ]]; then
    rm -f "${HOME}/.copilot/agents/${name}.agent.md" && ok "Removed stale Copilot agent: ${name}"
  fi
  if $DO_CODEX && [[ -f "${HOME}/.codex/agents/${name}.toml" ]]; then
    rm -f "${HOME}/.codex/agents/${name}.toml" && ok "Removed stale Codex agent: ${name}"
  fi
done
for name in "${RETIRED_AGENTS_SKILL_FALLBACK_ONLY[@]}"; do
  if $DO_CURSOR && [[ -d "$(global_path cursor)/${name}" ]]; then
    rm -rf "$(global_path cursor)/${name}" && ok "Removed stale Cursor skill-fallback agent: ${name}"
  fi
  if $DO_ANTIGRAVITY && [[ -d "$(global_path antigravity)/${name}" ]]; then
    rm -rf "$(global_path antigravity)/${name}" && ok "Removed stale Antigravity skill-fallback agent: ${name}"
  fi
done

# ── Agents: cross-tool, rendered from agent/ ────────────────────────────
# Claude Code, Copilot (VS Code), and Codex CLI each have a real, working,
# global custom-agent mechanism — in three incompatible formats. Cursor and
# Antigravity have none, so they get the same content as a Skill instead
# (skills auto-trigger on phrasing, so this isn't a downgrade). One source
# per agent (agent/<name>/AGENT.md), rendered per tool — see
# agent/README.md.
if [[ -f "${AGENTS_RENDER_SCRIPT}" && -d "${AGENTS_SRC_DIR}" ]]; then
  AGENT_NAMES=()
  for agent_dir in "${AGENTS_SRC_DIR}"/*/; do
    [[ -f "${agent_dir}AGENT.md" ]] || continue
    AGENT_NAMES+=("$(basename "${agent_dir}")")
  done

  if [[ ${#AGENT_NAMES[@]} -gt 0 ]]; then
    hdr "Agents (cross-tool, rendered from agent/)"
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
  warn "No scripts/agents_render.py or agent/ found — skipping agent install"
fi

# ── Freshness: global Claude Code SessionStart hook ──────────────────────────
# Every engineer has their own local clone of neeve-copilot — the shared
# house rules and skills only produce consistent answers across engineers if
# everyone's clone is actually current, not just "current as of
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

# ── Default agent: neeve as Claude Code's global default ────────────────────
# neeve routes every Design-Loop stage and enforces the process (right-sizing,
# PRD-as-system-of-record, cross-repo verification) — running as the session
# default means that's active from message one, not only when auto-trigger
# happens to match. Set ONCE, the first time `agent` is unset in
# ~/.claude/settings.json, via --only-if-unset: a routine sync must never
# silently override an engineer's own later choice (switched to a different
# agent, or deliberately unset it) — same "developer-local overrides win"
# principle as merge_house_rules.py never touching content outside its
# markers. Claude Code only; no equivalent default-agent mechanism confirmed
# for Copilot/Codex/Cursor/Antigravity (see agent/README.md).
if $DO_CLAUDE && [[ -f "${MERGE_DEFAULT_AGENT_SCRIPT}" ]]; then
  hdr "Default agent (Claude Code, global, set once)"
  DEFAULT_AGENT_OUT="$(python3 "${MERGE_DEFAULT_AGENT_SCRIPT}" "${HOME}/.claude/settings.json" "neeve" --only-if-unset)"
  if [[ "${DEFAULT_AGENT_OUT}" == Wrote:* ]]; then
    ok "Claude Code  →  ~/.claude/settings.json (agent=neeve set as default — first time only)"
  else
    ok "Claude Code  →  ~/.claude/settings.json (agent already set — left as your own choice, not overridden)"
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
echo "Agent (neeve — setup/onboarding + Design Loop routing) — invocation differs by tool:"
echo "  Claude Code:      DEFAULT AGENT as of this run, unless you'd already set your own"
echo "                     (~/.claude/settings.json's \"agent\" key — new session picks it up)"
echo "  Copilot (VS Code): type  @neeve  in chat (no prefix — Copilot's own @-mention syntax,"
echo "                     NOT Claude Code's @agent-<name>), or pick \"neeve\" from the Agents"
echo "                     dropdown. No default-agent mechanism exists for Copilot, so this is"
echo "                     the reliable invocation — don't rely on auto-trigger here."
echo "                     Repo-level routing content also auto-loads with no action needed"
echo "                     if that repo has run: bash <neeve-copilot>/neeve/init-repo.sh"
echo "                     (writes .github/copilot-instructions.md, git-committed)."
echo "  Codex CLI:         /agent  (explicit only, does not auto-trigger)"
echo "  Cursor/Antigravity: same as a skill — auto-triggers on phrasing"
