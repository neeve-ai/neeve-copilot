#!/usr/bin/env python3
"""Idempotently merge Neeve's rendered house-rules content into a user-level
global instructions file (~/.claude/CLAUDE.md, ~/.codex/AGENTS.md) that may
already contain the engineer's own unrelated personal content.

Replaces only the content between BEGIN/END markers on re-run, so running
the installer again after context/base.md changes updates the block in
place without touching anything else in the file.

Consistency, not bloat: the Neeve house rules are the single *gating* block —
there is exactly one, wrapped in the markers. Individual tool/personal
instructions in the same file are additive and are always preserved, never
overwritten. Installs that predate the markers left an un-marked copy of the
old house rules floating outside the block; this script strips that legacy
copy on the next run so the file never accumulates a stale, contradictory
second set of rules.

Usage: merge_house_rules.py <target-file> <house-rules-content-file>
"""
from __future__ import annotations

import sys
from pathlib import Path

BEGIN = "<!-- BEGIN NEEVE HOUSE RULES (managed by neeve-copilot, do not hand-edit this block) -->"
END = "<!-- END NEEVE HOUSE RULES -->"

# Stable title every rendered house-rules variant has started with. A copy of
# it sitting OUTSIDE the markers is a pre-marker install's leftover, not the
# engineer's own content — safe to remove, and removing it is what keeps the
# file from carrying two contradictory rule sets.
LEGACY_HEADER = "# Neeve Engineering — House Rules"


def _strip_legacy_unmarked_block(text: str) -> tuple[str, int]:
    """Remove an un-marked legacy house-rules copy from `text` (the portion of
    the file that lives before the managed block). Returns the cleaned text and
    the number of lines removed. Personal content above the legacy copy is
    preserved; only the region from our own title to the end of `text` goes."""
    idx = text.find(LEGACY_HEADER)
    if idx == -1:
        return text, 0
    removed = text[idx:]
    kept = text[:idx]
    return kept, removed.count("\n") + (0 if removed.endswith("\n") else 1)


def merge(target: Path, house_rules: str) -> int:
    """Write the single gating house-rules block into `target`, replacing any
    prior managed block and stripping any legacy un-marked copy. Returns the
    number of legacy lines removed (0 when there was nothing stale to clean)."""
    block = f"{BEGIN}\n\n{house_rules.strip()}\n\n{END}"

    if not target.is_file():
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(block + "\n")
        return 0

    existing = target.read_text()

    if BEGIN in existing and END in existing:
        before, _, rest = existing.partition(BEGIN)
        _, _, after = rest.partition(END)
    else:
        # No managed block yet — everything is "before"; a first-time marker
        # migration still needs the legacy copy at the tail stripped so we
        # don't end up with legacy + new block side by side.
        before, after = existing, ""

    before, removed_lines = _strip_legacy_unmarked_block(before)

    # Keep it lean: collapse trailing whitespace left behind by a strip so the
    # file doesn't grow a widening gap each run.
    before = before.rstrip("\n")
    separator = "\n\n" if before else ""
    new_content = f"{before}{separator}{block}"
    new_content += after if after.startswith("\n") else (f"\n{after}" if after else "\n")

    target.write_text(new_content)
    return removed_lines


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: merge_house_rules.py <target-file> <house-rules-content-file>", file=sys.stderr)
        return 2
    target = Path(sys.argv[1]).expanduser()
    house_rules_file = Path(sys.argv[2]).expanduser()
    removed = merge(target, house_rules_file.read_text())
    if removed:
        print(f"Merged house rules into: {target} (removed {removed} lines of stale legacy rules)")
    else:
        print(f"Merged house rules into: {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
