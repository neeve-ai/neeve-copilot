#!/usr/bin/env python3
"""Idempotently ensure one managed hook entry exists in a Claude Code
settings.json — mirrors merge_house_rules.py's idempotency discipline, but
for JSON structure instead of a markdown BEGIN/END block (JSON has no
comment syntax to mark "this block is managed here, don't hand-edit it").

This is the one place this system touches a file that can carry
security/permission-relevant settings, not just prose — every key and every
other hook already in the file is preserved untouched; only the one managed
entry (identified by a marker substring in its command, since that's the
only stable identity available) is added or updated.

Usage:
  merge_session_hook.py <settings.json path> <command> <marker> [matcher]
  merge_session_hook.py <settings.json path> --remove <marker>
"""
from __future__ import annotations

import json
import sys
from pathlib import Path


def merge(settings_path: Path, command: str, marker: str, matcher: str = "startup") -> None:
    if settings_path.is_file() and settings_path.stat().st_size > 0:
        data = json.loads(settings_path.read_text())
    else:
        data = {}

    hooks = data.setdefault("hooks", {})
    session_start = hooks.setdefault("SessionStart", [])

    # Look for our own previously-installed entry anywhere in SessionStart,
    # identified by the marker substring in its command — replace in place
    # if the underlying path/command changed (e.g. repo moved).
    for group in session_start:
        for entry in group.get("hooks", []):
            if marker in entry.get("command", ""):
                entry["command"] = command
                entry["type"] = "command"
                _write(settings_path, data)
                return

    # Not found — add to an existing matcher group of the right type if one
    # exists, so we don't create a second "startup" group unnecessarily.
    for group in session_start:
        if group.get("matcher") == matcher:
            group.setdefault("hooks", []).append({"type": "command", "command": command})
            _write(settings_path, data)
            return

    # No matching group at all — create one.
    session_start.append({"matcher": matcher, "hooks": [{"type": "command", "command": command}]})
    _write(settings_path, data)


def remove(settings_path: Path, marker: str) -> bool:
    """Remove the managed hook entry identified by `marker`. Idempotent: a
    settings.json with no such entry (or no file at all) is left untouched —
    including every other key, byte-for-byte, so this is safe to run
    whether or not the hook was ever installed."""
    if not settings_path.is_file() or settings_path.stat().st_size == 0:
        return False

    data = json.loads(settings_path.read_text())
    hooks = data.get("hooks")
    if not hooks:
        return False
    session_start = hooks.get("SessionStart")
    if not session_start:
        return False

    changed = False
    new_session_start = []
    for group in session_start:
        entries = group.get("hooks", [])
        kept = [entry for entry in entries if marker not in entry.get("command", "")]
        if len(kept) != len(entries):
            changed = True
        if kept:
            group["hooks"] = kept
            new_session_start.append(group)
        elif entries:
            # The whole group's hooks were ours — drop the now-empty group
            # rather than leaving a dangling matcher with no hooks.
            changed = True
        else:
            new_session_start.append(group)

    if not changed:
        return False

    if new_session_start:
        hooks["SessionStart"] = new_session_start
    else:
        del hooks["SessionStart"]
    if not hooks:
        del data["hooks"]

    _write(settings_path, data)
    return True


def _write(settings_path: Path, data: dict) -> None:
    settings_path.parent.mkdir(parents=True, exist_ok=True)
    settings_path.write_text(json.dumps(data, indent=2) + "\n")


def main() -> int:
    usage = (
        "Usage:\n"
        "  merge_session_hook.py <settings.json path> <command> <marker> [matcher]\n"
        "  merge_session_hook.py <settings.json path> --remove <marker>"
    )

    if len(sys.argv) == 4 and sys.argv[2] == "--remove":
        settings_path = Path(sys.argv[1]).expanduser().resolve()
        marker = sys.argv[3]
        removed = remove(settings_path, marker)
        print(f"{'Removed' if removed else 'No-op (not present)'}: {settings_path}")
        return 0

    if len(sys.argv) not in (4, 5):
        print(usage, file=sys.stderr)
        return 1
    settings_path = Path(sys.argv[1]).expanduser().resolve()
    command = sys.argv[2]
    marker = sys.argv[3]
    matcher = sys.argv[4] if len(sys.argv) == 5 else "startup"
    merge(settings_path, command, marker, matcher)
    print(f"Wrote: {settings_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
