#!/bin/sh
set -e

# Setup mock environment
export HOME="$(mktemp -d)"
export SHELL="/bin/sh"

touch "$HOME/.bashrc"

export COPILOT_HOME="$HOME/.copilot"
export INSTALL_DIR="$HOME/.neeve-copilot"
export AWESOME_DIR="$HOME/.awesome-copilot-source"

echo "Mocking an installed system..."
mkdir -p "$INSTALL_DIR/.agents/skills/dummy"
touch "$INSTALL_DIR/.agents/skills/dummy/SKILL.md"
mkdir -p "$AWESOME_DIR/agents/some-agent"
mkdir -p "$COPILOT_HOME"
mkdir -p "$HOME/.agents/skills"

# Run install mock to populate symlinks
# Run install.sh but mock out the git calls
sed -E 's/git clone/echo "Mock git clone"/g; s/git fetch/echo "Mock git fetch"/g; s/git reset/echo "Mock git reset"/g' install.sh > install_mocked.sh
sh install_mocked.sh > /dev/null

echo "Running uninstall.sh..."
sh uninstall.sh

echo "Asserting teardown..."

if [ -d "$INSTALL_DIR" ]; then
    echo "FAILED: $INSTALL_DIR was not deleted."
    exit 1
fi

if [ -d "$AWESOME_DIR" ]; then
    echo "FAILED: $AWESOME_DIR was not deleted."
    exit 1
fi

if [ -L "$COPILOT_HOME/agents" ]; then
    echo "FAILED: ~/.copilot/agents symlink was not deleted."
    exit 1
fi

if [ -L "$HOME/.agents/skills/dummy" ]; then
    echo "FAILED: ~/.agents/skills/dummy symlink was not deleted."
    exit 1
fi

if grep -q "Neeve Copilot Configuration" "$HOME/.bashrc"; then
    echo "FAILED: payload was not removed from .bashrc!"
    exit 1
fi

echo "All tests passed for uninstall.sh!"
rm -rf "$HOME"
rm -f install_mocked.sh
