#!/usr/bin/env bash
# One-time developer setup for contributing to neeve-copilot skills.
# Run once after cloning: bash setup-dev.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="${REPO_DIR}/.git-hooks"
GIT_HOOKS_DIR="${REPO_DIR}/.git/hooks"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()  { echo -e "  ${GREEN}✓${NC} $*"; }
warn(){ echo -e "  ${YELLOW}↻${NC} $*"; }

# 1. Install git hooks
warn "Installing git hooks from .git-hooks/..."
for hook in "${HOOKS_DIR}"/*; do
  name="$(basename "$hook")"
  cp "$hook" "${GIT_HOOKS_DIR}/${name}"
  chmod +x "${GIT_HOOKS_DIR}/${name}"
  ok "hook: ${name}"
done

# 2. Install skills locally
warn "Installing skills to all agents..."
bash "${REPO_DIR}/sync_skills.sh"

echo ""
ok "Dev setup complete."
echo ""
echo "  Workflow:"
echo "    1. Edit a skill in neeve/skills-src/ (or neeve/products/<product>/skills-src/ for product-specific ones)"
echo "    2. Test locally:  bash sync_skills.sh"
echo "    3. Commit:        git add ... && git commit -m 'skills: ...'"
echo "       → post-commit hook auto-pushes to origin when skills-src changes"
echo ""
echo "  To pick up changes made by others:"
echo "    bash sync_skills.sh"
