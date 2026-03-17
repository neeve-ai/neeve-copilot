# Neeve Copilot

Welcome to the `neeve-copilot` repository! This project centralizes Neeve-specific AI agents, workflows, and tools that seamlessly integrate into the standard AI coding assistant experience along with the wider `awesome-copilot` ecosystem.

## 🚀 Installation

To install `neeve-copilot` into your local environment:

```bash
curl -fsSL https://raw.githubusercontent.com/neeve-ai/neeve-copilot/main/install.sh | sh
```

You can then restart your terminal or manually source your `.zshrc` / `.bashrc`.

### 🔄 Updating

To update the directory anytime, simply type:

```bash
update-neeve-copilot
```

## 🗑️ Uninstalling

If you need to completely remove `neeve-copilot` and the underlying `awesome-copilot` agents from your system, you can run the uninstaller. This will selectively erase the folders and safely clean the configuration out of your `~/.bashrc` or `~/.zshrc`.

```bash
curl -fsSL https://raw.githubusercontent.com/neeve-ai/neeve-copilot/main/uninstall.sh | sh
```

## 🛠️ Adding New Skills

We organize our internal skills inside `.agents/skills/`.
To propose a new agent or skill:
1. Create a directory for your skill: `.agents/skills/my-skill/`
2. Define a `SKILL.md` file following the Open Agent Skills specification.
3. Commit and submit a Pull Request.

Our CI workflow checks and validates skills before they merge!

### Example `SKILL.md`

```md
---
name: Database Architect
description: Assists the developer in modeling database interactions
disabled: false
---

# Instructions
When discussing the database...
```
