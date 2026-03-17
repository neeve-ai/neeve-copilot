#!/bin/bash
set -e

# Setup mock environment
export HOME="$(mktemp -d)"

export COPILOT_HOME="$HOME/.copilot"
export NEEVE_SOURCE="$HOME/.neeve-copilot"
export AWESOME_SOURCE="$HOME/.awesome-copilot-source"

mkdir -p "$NEEVE_SOURCE/.agents/dummy-skill"
touch "$NEEVE_SOURCE/.agents/dummy-skill/SKILL.md"

mkdir -p "$AWESOME_SOURCE/agents/some-agent"
mkdir -p "$AWESOME_SOURCE/skills/some-skill"

echo "Running load_agents.sh..."
# Pass the contents of load_agents.sh slightly modified or just run it as a block?
# Running it as a script is easiest since env vars are passed down, except the script redefines them.
# So we need to evaluate the script text with our HOME variable.
bash load_agents.sh

echo "Asserting symlinks..."

if [ ! -L "$HOME/.agents/dummy-skill" ]; then
    echo "FAILED: Internal skill not linked to ~/.agents"
    exit 1
fi

if [ ! -L "$HOME/.copilot/agents" ]; then
    echo "FAILED: awesome copilot agents not linked."
    exit 1
fi

echo "All tests passed for load_agents.sh!"
rm -rf "$HOME"
