#!/usr/bin/env bash
# =============================================================================
# neeve/init-repo.sh — setup after cloning a Neeve product repo.
#
# Run FROM INSIDE the freshly-cloned product repo (or pass its path). Safe
# and expected to be re-run by EVERY engineer who clones this repo, even
# after a teammate already committed its .help/ book — steps 1-2 no-op on
# content that already exists, but step 3's `git config core.hooksPath` and
# step 6's default-agent setting are per-machine and can't travel via `git
# clone`, so re-running is how a second (or fifth) engineer picks them up:
#
#   cd ~/Projects/src/neeve/robin-ai
#   bash ~/Projects/src/neeve/neeve-copilot/neeve/init-repo.sh
#
# What it does (steps 1-5 committed into the product repo — the deliberate
# exception to "nothing per-repo": the OKF book and its freshness hook only
# work if every clone gets them. Step 6 is the opposite — machine-local,
# never committed; see its own note below):
#
#   1. Scaffolds the OKF book under .help/ at the repo root, if missing
#      (a dot-directory so it reads as tooling/metadata, and so a repo's
#      .dockerignore can exclude it from build/image context in one line):
#        .help/introduction.md — contextual README for agents (stack, wiring,
#                                make targets, docker, deploy), scaffolded
#                                with honest placeholders for repo-intel to
#                                fill from the repo itself
#        .help/index.md        — table of contents: functional area → location
#        .help/appendix.md     — public symbols: purpose, dependencies, impact
#        .help/memory.md        — bounded (~2,500 char) working-memory digest:
#                                current-state flags, quirks, conventions
#        .help/lessons.md       — corrections log (mistake → rule)
#      The scaffolds are honest skeletons full of TODO(repo-intel) markers —
#      the narrative content comes from running the repo-intel skill next,
#      never from this script guessing.
#   2. Scaffolds .help/reports/rca/ and .help/reports/retros/ (empty,
#      committed dirs via .gitkeep) — durable posterity for the
#      rca-retro-adr skill's RCA and Retro modes.
#   3. Installs .githooks/pre-commit (the deterministic context-sync check,
#      warn-only by default) and sets `git config core.hooksPath .githooks`.
#   4. Adds `.help/` to .dockerignore if the file exists and doesn't already
#      exclude it — the book is for agents, not the image build context.
#   5. With --with-ci: copies context-sync-check.yml (the CI backstop for
#      --no-verify) and integration-verify.yml (EDIT-ME template) into
#      .github/workflows/.
#   6. On Claude Code only: sets `.claude/settings.local.json`'s `agent` key
#      to `neeve`, so every Claude Code session opened in this repo starts
#      as the neeve agent by default — NOT the "commit into the repo"
#      exception steps 1-5 are. settings.local.json is machine-local and
#      never committed (Claude Code's own convention); this script adds it
#      to .gitignore explicitly since it — not Claude Code — creates the
#      file. Skip with --no-default-agent.
#
# Nothing here calls a model. Next step after this script: open the repo in
# your AI tool and run the repo-intel skill to fill the book from real code.
# =============================================================================
set -euo pipefail

COPILOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # neeve/
HOOK_TEMPLATE="${COPILOT_DIR}/templates/hooks/pre-commit-context-sync"
CI_TEMPLATES_DIR="${COPILOT_DIR}/templates/ci"
MERGE_DEFAULT_AGENT_SCRIPT="${COPILOT_DIR}/scripts/merge_default_agent.py"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}✓${NC} $*"; }
warn() { echo -e "  ${YELLOW}!${NC} $*"; }
err()  { echo -e "  ${RED}✗${NC} $*" >&2; }

WITH_CI=false
DEFAULT_AGENT=true
TARGET="."
for arg in "$@"; do
  case "$arg" in
    --with-ci) WITH_CI=true ;;
    --no-default-agent) DEFAULT_AGENT=false ;;
    -h|--help) sed -n '2,55p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) TARGET="$arg" ;;
  esac
done

cd "$TARGET"
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  err "Not a git repository: $(pwd) — run from inside the cloned product repo"
  exit 1
fi
cd "$(git rev-parse --show-toplevel)"
REPO_DIR="$(pwd)"

# ── Identify the repo name for the scaffold placeholders ─────────────────────
REPO_NAME="$(basename "${REPO_DIR}")"
origin_url="$(git remote get-url origin 2>/dev/null || true)"
if [[ -n "${origin_url}" ]]; then
  REPO_NAME="$(basename "${origin_url%.git}")"
fi

PRODUCT_ROLE="TODO(repo-intel): what this repo contributes to the product — grounded in the repo's actual code and docs."
STACK="TODO(repo-intel): languages, frameworks, package manager, versions — from the actual manifests, not memory."
TEST_CMD="TODO(repo-intel)"
LINT_CMD="TODO(repo-intel)"

# ── 1. Scaffold the OKF book under .help/ (never overwrite an existing file) ─
mkdir -p .help
scaffolded=""

if [[ ! -f .help/introduction.md ]]; then
  cat > .help/introduction.md <<INTRO
---
manifest-hash: 0000000000000000
---

# ${REPO_NAME} — Introduction (for agents)

> OKF book, 1 of 3 (introduction → index → appendix). The contextual README
> an AI agent reads FIRST: what this repo is, how it wires into the product,
> and how to build/run/test it. Kept current by .githooks/pre-commit +
> the repo-intel skill. The human-facing README.md is separate.

## Role in the product

${PRODUCT_ROLE}

## Tech stack

${STACK}

## How it wires into the product

TODO(repo-intel): what this service calls and what calls it — NATS subjects,
HTTP APIs consumed/exposed (link the OpenAPI contract if this is a backend),
MCP tools, queues. Name the direction of each dependency.

## Build / run / test

- Test: \`${TEST_CMD}\`
- Lint: \`${LINT_CMD}\`

TODO(repo-intel): every make target and what it does; how local dev spins up
(docker-compose file(s), env setup); how this deploys (Helm chart, which CI
workflow builds the image).
INTRO
  scaffolded="${scaffolded} .help/introduction.md"
fi

if [[ ! -f .help/index.md ]]; then
  cat > .help/index.md <<'INDEX'
# Index (for agents)

> OKF book, 2 of 3. The table of contents: functional areas mapped to where
> they live, so an agent jumps straight to the right place instead of
> grepping cold. Organized by feature/domain, not by directory listing.

| Functional area | Lives in | Entry point | Deep reference |
|---|---|---|---|
| TODO(repo-intel): e.g. Auth | `src/auth/**` | `src/auth/middleware.ts` | see appendix.md#AuthService |
INDEX
  scaffolded="${scaffolded} .help/index.md"
fi

if [[ ! -f .help/appendix.md ]]; then
  cat > .help/appendix.md <<'APPENDIX'
# Appendix (for agents)

> OKF book, 3 of 3. The deep reference: every public method/class with its
> purpose, dependencies (what it calls / what calls it), and impact if
> changed (blast radius). The pre-commit hook flags new/changed public
> symbols missing from this file as TODO(purpose) — visible, never silent.

<!-- One section per module. Format:

## ModuleName (`path/to/module`)

| Symbol | Purpose | Depends on / used by | Impact if changed |
|---|---|---|---|
| `ClassOrFunc` | what it's for | callers/callees | what breaks downstream |
-->

TODO(repo-intel): populate from a real scan.
APPENDIX
  scaffolded="${scaffolded} .help/appendix.md"
fi

if [[ ! -f .help/memory.md ]]; then
  cat > .help/memory.md <<'MEMORY'
# Memory (for agents)

> OKF book, 4 of 5. A deliberately bounded (~2,500 char) digest of durable
> *working* facts: current-state flags, operational quirks, and conventions
> learned during work. Not code reference — that's appendix.md. Consolidate,
> don't hoard: drop stale facts so every character earns its place. Updated
> directly by any skill mid-task (see engineering-principles.md's
> fact-routing rule), and consolidated/pruned during a full repo-intel pass.

TODO(repo-intel): nothing recorded yet — leave empty until a real
current-state fact, quirk, or convention is learned during work.
MEMORY
  scaffolded="${scaffolded} .help/memory.md"
fi

if [[ ! -f .help/lessons.md ]]; then
  cat > .help/lessons.md <<'LESSONS'
# Lessons (for agents)

> OKF book, 5 of 5. A corrections log (mistake → rule), read at the start of
> any nontrivial task in this repo. Appended directly by any skill mid-task
> when a user correction happens (see engineering-principles.md's
> fact-routing rule), and consolidated/deduped during a full repo-intel pass.

TODO(repo-intel): no corrections recorded yet.
LESSONS
  scaffolded="${scaffolded} .help/lessons.md"
fi

if [[ -n "${scaffolded}" ]]; then
  ok "Scaffolded:${scaffolded}"
else
  ok "OKF book already present (.help/introduction.md / .help/index.md / .help/appendix.md / .help/memory.md / .help/lessons.md) — left untouched"
fi

# ── 1b. Scaffold report dirs for the rca-retro-adr skill ────────────────────
mkdir -p .help/reports/rca .help/reports/retros
report_scaffolded=""
if [[ ! -f .help/reports/rca/.gitkeep ]]; then
  touch .help/reports/rca/.gitkeep
  report_scaffolded="${report_scaffolded} .help/reports/rca/"
fi
if [[ ! -f .help/reports/retros/.gitkeep ]]; then
  touch .help/reports/retros/.gitkeep
  report_scaffolded="${report_scaffolded} .help/reports/retros/"
fi
if [[ -n "${report_scaffolded}" ]]; then
  ok "Scaffolded:${report_scaffolded}"
else
  ok "Report dirs already present (.help/reports/rca/ / .help/reports/retros/) — left untouched"
fi

# ── 3. Install the committed pre-commit hook ─────────────────────────────────
mkdir -p .githooks
if [[ -f .githooks/pre-commit ]] && ! cmp -s "${HOOK_TEMPLATE}" .githooks/pre-commit; then
  warn ".githooks/pre-commit exists and differs from the template — left untouched"
  warn "  (diff it against ${HOOK_TEMPLATE} and reconcile manually)"
else
  cp "${HOOK_TEMPLATE}" .githooks/pre-commit
  chmod +x .githooks/pre-commit
  ok "Installed .githooks/pre-commit (context-sync, warn-only by default)"
fi
git config core.hooksPath .githooks
ok "git config core.hooksPath .githooks"

# Stamp the manifest hash so the very first commit doesn't warn spuriously.
python3 .githooks/pre-commit --stamp >/dev/null && ok "Stamped .help/introduction.md manifest-hash"

# ── 4. Keep the book out of the image build context ──────────────────────────
if [[ -f .dockerignore ]]; then
  if grep -qxF ".help" .dockerignore || grep -qxF ".help/" .dockerignore; then
    ok ".dockerignore already excludes .help/"
  else
    printf '\n# Agent-facing OKF book — not needed in the image build context\n.help/\n' >> .dockerignore
    ok "Added .help/ to .dockerignore"
  fi
else
  warn "No .dockerignore in this repo — skipped (add one + \".help/\" if this repo builds a Docker image)"
fi

# ── 5. Optional CI templates ─────────────────────────────────────────────────
if $WITH_CI; then
  mkdir -p .github/workflows
  for tmpl in context-sync-check.yml integration-verify.yml; do
    if [[ -f ".github/workflows/${tmpl}" ]]; then
      warn ".github/workflows/${tmpl} already exists — left untouched"
    else
      cp "${CI_TEMPLATES_DIR}/${tmpl}" ".github/workflows/${tmpl}"
      ok "Copied .github/workflows/${tmpl}"
    fi
  done
  warn "integration-verify.yml is an EDIT-ME template — it fails on purpose until"
  warn "you set this repo's real integration test command."
fi

# ── 6. Claude Code default agent (machine-local, NEVER committed) ────────────
# Every other step above is committed so a teammate's clone inherits it for
# free. This one is the opposite by design: Claude Code's own docs make the
# "run as this agent by default" mechanism project-scoped
# (.claude/settings.local.json), and that file is meant to stay
# machine-local — so each engineer runs this step themselves (this script is
# meant to be re-run safely on a repo someone else already initialized; see
# step 3's unconditional `git config core.hooksPath` for the same pattern).
# Harmless to write even for engineers on other tools — they simply never
# read .claude/.
if $DEFAULT_AGENT; then
  if [[ -f "${MERGE_DEFAULT_AGENT_SCRIPT}" ]]; then
    python3 "${MERGE_DEFAULT_AGENT_SCRIPT}" ".claude/settings.local.json" "neeve" >/dev/null
    ok "Claude Code default agent: .claude/settings.local.json (agent=neeve, not committed)"
  else
    warn "scripts/merge_default_agent.py not found — skipped default-agent setup"
  fi
  if [[ -f .gitignore ]]; then
    if grep -qxF ".claude/settings.local.json" .gitignore; then
      ok ".gitignore already excludes .claude/settings.local.json"
    else
      printf '\n# Machine-local Claude Code settings (default agent) — never commit\n.claude/settings.local.json\n' >> .gitignore
      ok "Added .claude/settings.local.json to .gitignore"
    fi
  else
    warn "No .gitignore in this repo — add one with \".claude/settings.local.json\" so it's never committed"
  fi
else
  warn "Skipped Claude Code default-agent setup (--no-default-agent)"
fi

# ── Next steps ────────────────────────────────────────────────────────────────
echo ""
echo "Done. Commit the result on a branch and open a PR:"
echo "  git checkout -b chore/okf-book-init"
GIT_ADD_LIST=".help/ .githooks/ .dockerignore .gitignore"
$WITH_CI && GIT_ADD_LIST="${GIT_ADD_LIST} .github/workflows/"
echo "  git add ${GIT_ADD_LIST}"
echo "  git commit -m 'chore: init OKF book + context-sync hook (neeve-copilot init-repo.sh)'"
echo ""
echo "(.claude/settings.local.json is deliberately NOT in that list — it's your"
echo " own machine-local default-agent setting, gitignored on purpose. Every"
echo " teammate re-runs this script once to get their own copy — that's expected,"
echo " not a sign they missed something; steps 1-5 no-op safely on their re-run.)"
echo ""
echo "Then fill the book from real code: open this repo in your AI tool and run"
echo "the repo-intel skill (\"map this repo\") — it replaces every TODO(repo-intel)"
echo "marker with scanned, cited content and re-stamps the manifest hash."
