#!/usr/bin/env python3
"""Idempotently merge Neeve's rendered house-rules content into a user-level
global instructions file (~/.claude/CLAUDE.md, ~/.codex/AGENTS.md) that may
already contain the engineer's own unrelated personal content.

Replaces only the content between BEGIN/END markers on re-run, so running
the installer again after context-src/base.md changes updates the block in
place without touching anything else in the file.

Usage: merge_house_rules.py <target-file> <house-rules-content-file>
"""
from __future__ import annotations

import sys
from pathlib import Path

BEGIN = "<!-- BEGIN NEEVE HOUSE RULES (managed by neeve-copilot, do not hand-edit this block) -->"
END = "<!-- END NEEVE HOUSE RULES -->"


def merge(target: Path, house_rules: str) -> None:
    block = f"{BEGIN}\n\n{house_rules.strip()}\n\n{END}"

    if not target.is_file():
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(block + "\n")
        return

    existing = target.read_text()
    if BEGIN in existing and END in existing:
        before, _, rest = existing.partition(BEGIN)
        _, _, after = rest.partition(END)
        new_content = before + block + after
    else:
        # First time this file has seen the block — append, preserving
        # whatever personal content the engineer already had.
        separator = "\n\n" if existing and not existing.endswith("\n\n") else ""
        new_content = existing + separator + block + "\n"

    target.write_text(new_content)


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: merge_house_rules.py <target-file> <house-rules-content-file>", file=sys.stderr)
        return 2
    target = Path(sys.argv[1]).expanduser()
    house_rules_file = Path(sys.argv[2]).expanduser()
    merge(target, house_rules_file.read_text())
    print(f"Merged house rules into: {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
