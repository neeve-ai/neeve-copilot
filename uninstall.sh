#!/bin/sh
# shellcheck shell=dash
# shellcheck disable=SC2039  # local is non-POSIX
# shellcheck disable=SC2268  # no harm in supporting older shells
set -e

# Configuration
INSTALL_DIR="$HOME/.neeve-copilot"
AWESOME_DIR="$HOME/.awesome-copilot-source"
COPILOT_HOME="$HOME/.copilot"

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

printf "%b\n" "${BLUE}🗑️  Uninstalling Neeve Copilot...${NC}"

# 1. Clean up Symlinks safely
printf "%b\n" "${YELLOW}🧹 Removing symlinks...${NC}"

# We only remove specific links that load_agents.sh created, rather than the whole folders.
[ -h "$COPILOT_HOME/agents/some-agent" ] && rm -f "$COPILOT_HOME/agents/some-agent" # awesome copilot usually links subdirs, wait, it links the whole folder. 
# Re-reading load_agents.sh:
# safe_link "$AWESOME_SOURCE/agents" "$COPILOT_HOME/agents"
# This symlinks the entire directory as `~/.copilot/agents`

[ -h "$COPILOT_HOME/agents" ] && rm -f "$COPILOT_HOME/agents"
[ -h "$COPILOT_HOME/skills" ] && rm -f "$COPILOT_HOME/skills"
[ -h "$COPILOT_HOME/hooks" ] && rm -f "$COPILOT_HOME/hooks"
[ -h "$COPILOT_HOME/workflows" ] && rm -f "$COPILOT_HOME/workflows"
[ -h "$COPILOT_HOME/plugins" ] && rm -f "$COPILOT_HOME/plugins"
[ -h "$COPILOT_HOME/system_instructions" ] && rm -f "$COPILOT_HOME/system_instructions"

# For Neeve internal skills, we symlink the individual elements:
if [ -d "$INSTALL_DIR/.agents/skills" ]; then
    for item in "$INSTALL_DIR/.agents/skills"/*; do
        if [ -d "$item" ]; then
            basename=$(basename "$item")
            [ -h "$HOME/.agents/skills/$basename" ] && rm -f "$HOME/.agents/skills/$basename"
        fi
    done
fi

# 2. Delete source directories
printf "%b\n" "${YELLOW}🗑️  Deleting source clones...${NC}"
[ -d "$INSTALL_DIR" ] && rm -rf "$INSTALL_DIR"
[ -d "$AWESOME_DIR" ] && rm -rf "$AWESOME_DIR"

# 3. Scrub shell profiles
printf "%b\n" "${YELLOW}🧼 Scrubbing shell profiles...${NC}"
remove_from_profile() {
    PROFILE_FILE="$1"
    if [ -f "$PROFILE_FILE" ]; then
        if grep -q "Neeve Copilot Configuration" "$PROFILE_FILE"; then
            echo "   Cleaning $PROFILE_FILE"
            # Use sed to delete lines starting from the marker until the alias
            # We use a backup extension (.bak) for maximum compatibility across macOS/Linux
            sed -i.bak '/# Neeve Copilot Configuration/,/alias update-neeve-copilot=.*/d' "$PROFILE_FILE"
            # Clean up the backup file sed creates
            rm -f "${PROFILE_FILE}.bak"
        fi
    fi
}

remove_from_profile "$HOME/.zshrc"
remove_from_profile "$HOME/.bashrc"
remove_from_profile "$HOME/.profile"

printf "%b\n" "${GREEN}✅ Uninstallation complete! Restart your terminal to clear active loaded aliases.${NC}"
