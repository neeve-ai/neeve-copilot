#!/bin/sh
# shellcheck shell=dash
# shellcheck disable=SC2039  # local is non-POSIX
# shellcheck disable=SC2268  # no harm in supporting older shells
# Sourced by user profile (~/.zshrc or ~/.bashrc)
# Loads Awesome Copilot and Neeve Copilot skills dynamically.

COPILOT_HOME="$HOME/.copilot"
NEEVE_SOURCE="$HOME/.neeve-copilot"
AWESOME_SOURCE="$HOME/.awesome-copilot-source"

# Ensure core directory exists
# mkdir -p "$COPILOT_HOME/system_instructions"
mkdir -p "$COPILOT_HOME"
mkdir -p "$HOME/.agents/skills"

# Safety Link Function
safe_link() {
    [ -d "$1" ] && ln -sfn "$1" "$2"
}

# 1. Map Awesome Copilot (External)
if [ -d "$AWESOME_SOURCE" ]; then
    safe_link "$AWESOME_SOURCE/agents" "$COPILOT_HOME/agents"
    safe_link "$AWESOME_SOURCE/skills" "$COPILOT_HOME/skills"
    safe_link "$AWESOME_SOURCE/hooks" "$COPILOT_HOME/hooks"
    safe_link "$AWESOME_SOURCE/workflows" "$COPILOT_HOME/workflows"
    safe_link "$AWESOME_SOURCE/plugins" "$COPILOT_HOME/plugins"
    safe_link "$AWESOME_SOURCE/instructions" "$COPILOT_HOME/system_instructions"
fi

# 2. Map Neeve Internal Skills
if [ -d "$NEEVE_SOURCE/.agents/skills" ]; then
    # Let's symlink the files/directories inside `.agents/skills` to `~/.agents/skills/` so we don't completely hijack `~/.agents/skills`.

    for item in "$NEEVE_SOURCE/.agents/skills"/*; do
        if [ -d "$item" ]; then
            basename=$(basename "$item")
            safe_link "$item" "$HOME/.agents/skills/$basename"
        fi
    done
fi
