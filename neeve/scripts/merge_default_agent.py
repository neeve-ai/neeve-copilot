#!/usr/bin/env python3
"""Idempotently set the `agent` key in a Claude Code settings.json — mirrors
merge_session_hook.py's idempotency discipline for the same reason: only the
one key we own is touched, every other key already in the file (permissions,
hooks, MCP servers, personal overrides) is preserved untouched.

Deliberately generic over which settings.json (global, project, or local) —
the caller decides scope; this script never guesses it. It exists because
this project's own `.claude/settings.local.json` is used for the
default-agent setting specifically so it is machine-local and never
committed (see init-repo.sh), unlike every other file this system writes.

Usage: merge_default_agent.py <settings.json path> <agent-name>
"""
from __future__ import annotations

import json
import sys
from pathlib import Path


def merge(settings_path: Path, agent_name: str) -> bool:
    """Returns True if the file changed, False if it already matched."""
    if settings_path.is_file() and settings_path.stat().st_size > 0:
        data = json.loads(settings_path.read_text())
    else:
        data = {}

    if data.get("agent") == agent_name:
        return False

    data["agent"] = agent_name
    settings_path.parent.mkdir(parents=True, exist_ok=True)
    settings_path.write_text(json.dumps(data, indent=2) + "\n")
    return True


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: merge_default_agent.py <settings.json path> <agent-name>", file=sys.stderr)
        return 1
    settings_path = Path(sys.argv[1]).expanduser().resolve()
    agent_name = sys.argv[2]
    changed = merge(settings_path, agent_name)
    print(f"{'Wrote' if changed else 'Already set'}: {settings_path} (agent={agent_name})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
