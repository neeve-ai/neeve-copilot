# Feature Reference: Neeve Copilot Distribution System

## Feature Name
Neeve Copilot Distribution System (Installer, Loader, and Uninstaller)

## Description
A central distribution system that allows developers to seamlessly install, update, and remove Neeve-specific AI agents and community-driven `awesome-copilot` agents on their local machines. This repository provides robust shell scripts that configure the user's terminal to natively load these agents right into their Copilot IDE seamlessly.

## Key Functionalities
- **Automated Installation (`install.sh`)**: One-line command to fetch the `neeve-copilot` and `awesome-copilot` repositories efficiently using shallow clones. Automatically injects the necessary configurations into the user's shell profile (`.bashrc` / `.zshrc`).
- **Dynamic Agent Loader (`load_agents.sh`)**: Exposes downloaded scripts and agents directly to the Copilot environment (`~/.copilot` and `~/.agents/skills`) using safe symlinking. 
- **Automated Update Alias (`update-neeve-copilot`)**: A built-in shell alias that triggers a fresh download and update of the installation script directly from the remote origin, allowing developers to pull the newest agents effortlessly.
- **Clean Uninstallation (`uninstall.sh`)**: Safely removes the injected configuration from shell profiles and intelligently removes the agent symlinks without wiping custom user agents that might share the same directories.
- **Continuous Integration Pipeline (`ci.yml`)**: Automated GitHub Actions testing that enforces the Open Agent Skills specification (verifying `name` and `description` in YAML frontmatter for all components) and validates the installation shell logic against POSIX compliance.

## User Flow
1. **Install:** A developer opens their terminal and runs `curl -fsSL https://raw.githubusercontent.com/neeve-ai/neeve-copilot/main/install.sh | sh`.
2. **Reload Shell:** The developer restarts their terminal or runs `source ~/.bashrc` / `~/.zshrc`. 
3. **Usage:** The developer uses their IDE Copilot. The internal Neeve skills (from `.agents/skills`) and community skills (from `awesome-copilot`) are automatically available in the AI assistant.
4. **Update:** The developer runs `update-neeve-copilot` anytime to sync the latest available agents.
5. **Uninstall:** If desired, the developer removes everything cleanly by executing `curl .../uninstall.sh | sh`.

## Technical Implementation
- **POSIX Shell Architecture**: All scripts (`sh`) are written strictly according to POSIX standards avoiding `bashism` to ensure seamless execution across macOS (zsh), Linux (bash/dash), and Windows (git-bash).
- **Symlinking Strategy**: To avoid overwriting a developer's manually created agents, the script maps the target resources using isolated symlinks natively traversing from `$INSTALL_DIR` to `~/.agents/skills/` and `~/.copilot/`.
- **Stateless Updates**: During an update, the system relies on performing `git fetch --depth=1` and `git reset --hard FETCH_HEAD` to avoid preserving massive Git histories locally.
- **Shell Injection (`sed`)**: The configuration logic explicitly adds `# Neeve Copilot Configuration` marker comments. The uninstaller relies on `sed '/# Neeve.../,/alias.../d'` to safely delete only what was injected.

## Non-functional requirements
- **Compatibility**: Must natively run on POSIX-compliant setups (macOS `zsh`, Linux `bash/dash`, Windows `git-bash`).
- **Performance**: Git clones must use `--depth 1` to ensure rapid downloads. No heavy binaries should be packaged.
- **Safety**: Do not permanently modify or delete the `~/.agents` or `~/.copilot` parent directories as they belong to the developer.

## Open questions / decisions
- **Skill Versioning**: How should we handle breaking changes in agent specifications if `awesome-copilot` introduces a structurally different format? Currently pinned to `main` branch latest.
- **Offline Mode**: Is there a requirement to provide an offline backup/cache of the latest fetched `awesome-copilot` if GitHub is unavailable?
- **Alias Expansion**: Could we expand `update-neeve-copilot` into a full CLI tool rather than an alias for more advanced management (e.g., listing agents locally vs remotely)?
