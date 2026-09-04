#!/usr/bin/env python3
"""Idempotently merge Neeve-managed content into a target markdown file that
may already contain other, unrelated content (an engineer's personal
instructions, a team's own repo conventions).

Replaces only the content between BEGIN/END markers on re-run, so running
the installer again after the source content changes updates the block in
place without touching anything else in the file.

Consistency, not bloat: Neeve's content is a single *gating* block per
label — there is exactly one, wrapped in the markers. Everything else in the
same file is additive and always preserved, never overwritten.

Two call sites, same mechanism, different `label`/content:
- House rules (default label, install.sh, global): `context/base.md`'s
  rendered content into `~/.claude/CLAUDE.md` / `~/.codex/AGENTS.md`.
  Installs that predate the markers left an un-marked copy of the old house
  rules floating outside the block; this script strips that legacy copy on
  the next run so the file never accumulates a stale, contradictory second
  set of rules (see `_strip_legacy_unmarked_block`).
- Repo-level Copilot instructions (`label="NEEVE ROUTING GUIDE"`,
  init-repo.sh, per repo, COMMITTED): `agent/neeve/AGENT.md`'s body into a
  repo's `.github/copilot-instructions.md`, which GitHub auto-loads for
  every Copilot user in that repo — no picker/mention needed, and unlike
  the Claude Code default-agent setting, this one travels via `git clone`
  for free once one engineer commits it. No legacy content to strip here
  (this label never had a pre-marker era), so `legacy_header=None` disables
  that step for this call site — same merge() function, no duplicated code.

Usage: merge_house_rules.py <target-file> <content-file> [label]
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

DEFAULT_LABEL = "NEEVE HOUSE RULES"

# Stable title every rendered house-rules variant has started with. A copy of
# it sitting OUTSIDE the markers is a pre-marker install's leftover, not the
# engineer's own content — safe to remove, and removing it is what keeps the
# file from carrying two contradictory rule sets. Only meaningful for the
# house-rules label; other labels never had this problem (see module
# docstring), so callers pass legacy_header=None for those.
LEGACY_HEADER = "# Neeve Engineering — House Rules"

# Backward-compatible constants for existing callers/tests that reference the
# default label's exact markers directly.
BEGIN = f"<!-- BEGIN {DEFAULT_LABEL} (managed by neeve-copilot, do not hand-edit this block) -->"
END = f"<!-- END {DEFAULT_LABEL} -->"


def _strip_legacy_unmarked_block(text: str, legacy_header: str) -> tuple[str, int]:
    """Remove an un-marked legacy copy from `text` (the portion of the file
    that lives before the managed block). Returns the cleaned text and the
    number of lines removed. Personal content above the legacy copy is
    preserved. The legacy header must match a whole line exactly (not just
    appear as a substring somewhere in the file), and removal stops at the
    next top-level `#` heading rather than running to the end of `text`, so
    any of the engineer's own content that follows the legacy block
    survives."""
    lines = text.split("\n")
    legacy_idx = next(
        (i for i, line in enumerate(lines) if line.rstrip("\r") == legacy_header), None
    )
    if legacy_idx is None:
        return text, 0

    next_heading_idx = next(
        (
            i
            for i in range(legacy_idx + 1, len(lines))
            if re.match(r"^#\s", lines[i])
        ),
        len(lines),
    )

    kept = lines[:legacy_idx] + lines[next_heading_idx:]
    removed_lines = next_heading_idx - legacy_idx
    return "\n".join(kept), removed_lines


def merge(
    target: Path,
    content: str,
    label: str = DEFAULT_LABEL,
    legacy_header: str | None = LEGACY_HEADER,
) -> int:
    """Write the single gating block (identified by `label`) into `target`,
    replacing any prior managed block for that label and stripping any
    legacy un-marked copy (skipped entirely if legacy_header is None — see
    module docstring for which call sites need it). Returns the number of
    legacy lines removed (0 when there was nothing stale to clean)."""
    begin = f"<!-- BEGIN {label} (managed by neeve-copilot, do not hand-edit this block) -->"
    end = f"<!-- END {label} -->"
    block = f"{begin}\n\n{content.strip()}\n\n{end}"

    if not target.is_file():
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(block + "\n")
        return 0

    existing = target.read_text()

    if begin in existing and end in existing:
        before, _, rest = existing.partition(begin)
        _, _, after = rest.partition(end)
    else:
        # No managed block yet — everything is "before"; a first-time marker
        # migration still needs the legacy copy at the tail stripped so we
        # don't end up with legacy + new block side by side.
        before, after = existing, ""

    removed_lines = 0
    if legacy_header is not None:
        # Only this path can destroy content the engineer wrote (the legacy
        # strip below), so only it needs a safety-net backup. The other call
        # site's target is COMMITTED into a product repo (see module
        # docstring) — dropping an untracked `.bak` there on every run would
        # be its own kind of repo pollution, not a safety net.
        target.with_name(target.name + ".bak").write_text(existing)
        before, removed_lines = _strip_legacy_unmarked_block(before, legacy_header)

    # Keep it lean: collapse trailing whitespace left behind by a strip so the
    # file doesn't grow a widening gap each run.
    before = before.rstrip("\n")
    separator = "\n\n" if before else ""
    new_content = f"{before}{separator}{block}"
    new_content += after if after.startswith("\n") else (f"\n{after}" if after else "\n")

    target.write_text(new_content)
    return removed_lines


def main() -> int:
    if len(sys.argv) not in (3, 4):
        print("Usage: merge_house_rules.py <target-file> <content-file> [label]", file=sys.stderr)
        return 2
    target = Path(sys.argv[1]).expanduser()
    content_file = Path(sys.argv[2]).expanduser()
    label = sys.argv[3] if len(sys.argv) == 4 else DEFAULT_LABEL
    legacy_header = LEGACY_HEADER if label == DEFAULT_LABEL else None
    removed = merge(target, content_file.read_text(), label=label, legacy_header=legacy_header)
    if removed:
        print(f"Merged into: {target} (label={label!r}, removed {removed} lines of stale legacy content)")
    else:
        print(f"Merged into: {target} (label={label!r})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
