#!/bin/sh
set -e

# Setup mock environment
export HOME="$(mktemp -d)"
export SHELL="/bin/sh"

touch "$HOME/.bashrc"

echo "Running install.sh in test mode (HOME=$HOME)..."
# Mock the git clones to prevent network calls and auth issues in tests
mkdir -p "$HOME/.neeve-copilot" "$HOME/.awesome-copilot-source"
export INSTALL_DIR="$HOME/.neeve-copilot" 
export AWESOME_DIR="$HOME/.awesome-copilot-source"

# Run install.sh but mock out the git calls
sed -E 's/git clone/echo "Mock git clone"/g; s/git fetch/echo "Mock git fetch"/g; s/git reset/echo "Mock git reset"/g' install.sh > install_mocked.sh
sh install_mocked.sh

if [ ! -d "$HOME/.awesome-copilot-source" ]; then
    echo "FAILED: .awesome-copilot-source directory not created."
    exit 1
fi

if ! grep -q "Neeve Copilot Configuration" "$HOME/.bashrc"; then
    echo "FAILED: Payload not injected into .bashrc"
    exit 1
fi

echo "All tests passed for install.sh!"
rm -rf "$HOME"
