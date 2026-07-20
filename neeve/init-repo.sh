#!/usr/bin/env bash
# =============================================================================
# neeve/init-repo.sh — one-time setup after cloning a Neeve product repo.
#
# Run FROM INSIDE the freshly-cloned product repo (or pass its path):
#
#   cd ~/Projects/src/neeve/robin-ai
#   bash ~/Projects/src/neeve/neeve-copilot/neeve/init-repo.sh
#
# What it does (all committed into the product repo — this is the deliberate
# exception to "nothing per-repo": the OKF book and its freshness hook only
# work if every clone gets them):
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
#      The scaffolds are honest skeletons full of TODO(repo-intel) markers —
#      the narrative content comes from running the repo-intel skill next,
#      never from this script guessing.
#   2. Installs .githooks/pre-commit (the deterministic context-sync check,
#      warn-only by default) and sets `git config core.hooksPath .githooks`.
#   3. Adds `.help/` to .dockerignore if the file exists and doesn't already
#      exclude it — the book is for agents, not the image build context.
#   4. With --with-ci: copies context-sync-check.yml (the CI backstop for
#      --no-verify) and integration-verify.yml (EDIT-ME template) into
#      .github/workflows/.
#
# Nothing here calls a model. Next step after this script: open the repo in
# your AI tool and run the repo-intel skill to fill the book from real code.
# =============================================================================
set -euo pipefail

COPILOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # neeve/
HOOK_TEMPLATE="${COPILOT_DIR}/templates/hooks/pre-commit-context-sync"
CI_TEMPLATES_DIR="${COPILOT_DIR}/templates/ci"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}✓${NC} $*"; }
warn() { echo -e "  ${YELLOW}!${NC} $*"; }
err()  { echo -e "  ${RED}✗${NC} $*" >&2; }

WITH_CI=false
TARGET="."
for arg in "$@"; do
  case "$arg" in
    --with-ci) WITH_CI=true ;;
    -h|--help) sed -n '2,30p' "${BASH_SOURCE[0]}"; exit 0 ;;
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

if [[ -n "${scaffolded}" ]]; then
  ok "Scaffolded:${scaffolded}"
else
  ok "OKF book already present (.help/introduction.md / .help/index.md / .help/appendix.md) — left untouched"
fi

# ── 2. Install the committed pre-commit hook ─────────────────────────────────
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

# ── 3. Keep the book out of the image build context ──────────────────────────
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

# ── 4. Optional CI templates ─────────────────────────────────────────────────
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

# ── Next steps ────────────────────────────────────────────────────────────────
echo ""
echo "Done. Commit the result on a branch and open a PR:"
echo "  git checkout -b chore/okf-book-init"
echo "  git add .help/ .githooks/ .dockerignore${WITH_CI:+ .github/workflows/}"
echo "  git commit -m 'chore: init OKF book + context-sync hook (neeve-copilot init-repo.sh)'"
echo ""
echo "Then fill the book from real code: open this repo in your AI tool and run"
echo "the repo-intel skill (\"map this repo\") — it replaces every TODO(repo-intel)"
echo "marker with scanned, cited content and re-stamps the manifest hash."
