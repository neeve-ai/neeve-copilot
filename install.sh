#!/bin/bash
set -e

# Configuration
REPO_URL="https://github.com/neeve/neeve-copilot.git"
INSTALL_DIR="$HOME/.neeve-copilot"
AWESOME_URL="https://github.com/github/awesome-copilot.git"
AWESOME_DIR="$HOME/.awesome-copilot-source"

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🛠️  Installing Neeve Copilot Skills...${NC}"

# 1. Clone/Update Neeve Repo
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}📥 Fetching neeve-copilot...${NC}"
    git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
else
    echo -e "${YELLOW}🔄 Updating Neeve repo...${NC}"
    cd "$INSTALL_DIR" && git fetch --quiet --depth=1 origin main && git reset --quiet --hard FETCH_HEAD && cd - > /dev/null
fi

# 2. Clone/Update Awesome-Copilot (Dependency)
if [ ! -d "$AWESOME_DIR" ]; then
    echo -e "${YELLOW}📥 Fetching awesome-copilot base...${NC}"
    git clone --depth 1 "$AWESOME_URL" "$AWESOME_DIR"
else
    echo -e "${YELLOW}🔄 Updating awesome-copilot base...${NC}"
    cd "$AWESOME_DIR" && git fetch --quiet --depth=1 origin main && git reset --quiet --hard FETCH_HEAD && cd - > /dev/null
fi

# 3. Inject into Shell Profile
DETECTED_PROFILE=""
if [[ "$SHELL" == */zsh ]]; then
    DETECTED_PROFILE="$HOME/.zshrc"
elif [[ "$SHELL" == */bash ]]; then
    DETECTED_PROFILE="$HOME/.bashrc"
fi

# Provide a fallback if SHELL detection fails
if [ -z "$DETECTED_PROFILE" ]; then
    if [ -f "$HOME/.zshrc" ]; then
        DETECTED_PROFILE="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        DETECTED_PROFILE="$HOME/.bashrc"
    else
        DETECTED_PROFILE="$HOME/.profile"
    fi
fi

if [ -n "$DETECTED_PROFILE" ]; then
    # Add payload if missing
    if ! grep -q "Neeve Copilot Configuration" "$DETECTED_PROFILE"; then
        echo -e "${GREEN}✍️ Adding loader to $DETECTED_PROFILE${NC}"
        
        cat << 'EOF' >> "$DETECTED_PROFILE"

# Neeve Copilot Configuration
[ -f ~/.neeve-copilot/load_agents.sh ] && source ~/.neeve-copilot/load_agents.sh
alias update-neeve-copilot='bash ~/.neeve-copilot/install.sh'
EOF
    else
        echo -e "${GREEN}✅ Loader already present in $DETECTED_PROFILE${NC}"
    fi
else
    echo -e "${RED}⚠️ Could not detect a suitable shell profile to update.${NC}"
    echo "Please manually add the following to your shell configuration:"
    echo "  [ -f ~/.neeve-copilot/load_agents.sh ] && source ~/.neeve-copilot/load_agents.sh"
    echo "  alias update-neeve-copilot='bash ~/.neeve-copilot/install.sh'"
fi

# 4. Finalize
if [ -f "$INSTALL_DIR/load_agents.sh" ]; then
    bash "$INSTALL_DIR/load_agents.sh"
fi

echo -e "${GREEN}✅ Success! Restart your terminal or run: source $DETECTED_PROFILE${NC}"
