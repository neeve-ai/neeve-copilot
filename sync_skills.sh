#!/usr/bin/env bash
# Pulls the latest from neeve-copilot and reinstalls all skills for every agent.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="${REPO_DIR}/neeve/products/robin/install.sh"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()  { echo -e "  ${GREEN}✓${NC} $*"; }
warn(){ echo -e "  ${YELLOW}↻${NC} $*"; }
err() { echo -e "  ${RED}✗${NC} $*"; exit 1; }

warn "Pulling latest from origin ($(git -C "$REPO_DIR" branch --show-current))..."
git -C "$REPO_DIR" pull origin "$(git -C "$REPO_DIR" branch --show-current)"
ok "Repo up to date"

if [[ ! -f "$INSTALLER" ]]; then
  err "Installer not found at $INSTALLER"
fi

warn "Running install.sh --all..."
bash "$INSTALLER" --all
