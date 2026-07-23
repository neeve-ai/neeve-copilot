#!/usr/bin/env python3
"""Tests for merge_house_rules.py — stdlib unittest only, no new dependency."""
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import merge_house_rules as mhr


class MergeHouseRulesTests(unittest.TestCase):
    def test_fresh_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "CLAUDE.md"
            mhr.merge(target, "some house rules content")
            text = target.read_text()
            self.assertIn(mhr.BEGIN, text)
            self.assertIn(mhr.END, text)
            self.assertIn("some house rules content", text)

    def test_preserves_existing_personal_content(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "CLAUDE.md"
            target.write_text("# My personal prefs\n- always use tabs\n")
            mhr.merge(target, "house rules v1")
            text = target.read_text()
            self.assertIn("always use tabs", text)
            self.assertIn("house rules v1", text)

    def test_rerun_replaces_block_without_duplicating(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "CLAUDE.md"
            target.write_text("# My personal prefs\n- always use tabs\n")
            mhr.merge(target, "house rules v1")
            mhr.merge(target, "house rules v2")
            text = target.read_text()
            self.assertEqual(text.count(mhr.BEGIN), 1)
            self.assertEqual(text.count("always use tabs"), 1)
            self.assertNotIn("house rules v1", text)
            self.assertIn("house rules v2", text)

    def test_strips_legacy_unmarked_block_when_markers_present(self) -> None:
        # Reproduces a pre-marker install: an un-marked legacy copy sits above
        # the current managed block. Re-merging must remove the legacy copy so
        # only one gating block survives — no bloat, no contradiction.
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "CLAUDE.md"
            legacy = f"{mhr.LEGACY_HEADER}\n\nOLD RULES referencing retired agents\n\n"
            managed = f"{mhr.BEGIN}\n\nhouse rules v1\n\n{mhr.END}\n"
            target.write_text(legacy + managed)
            # Real rendered content starts with the header, so post-merge the
            # header appears exactly once — inside the single managed block.
            removed = mhr.merge(target, f"{mhr.LEGACY_HEADER}\n\nhouse rules v2")
            text = target.read_text()
            self.assertGreater(removed, 0)
            self.assertEqual(text.count(mhr.BEGIN), 1)
            self.assertEqual(text.count(mhr.LEGACY_HEADER), 1)  # only inside the block
            self.assertNotIn("OLD RULES referencing retired agents", text)
            self.assertIn("house rules v2", text)

    def test_strips_legacy_on_first_marker_migration(self) -> None:
        # Pre-marker file that has NEVER had markers: legacy copy at the tail,
        # no BEGIN/END yet. First marker-era merge must strip it, not append a
        # second set of rules beside it.
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "AGENTS.md"
            target.write_text(f"{mhr.LEGACY_HEADER}\n\nOLD RULES body\n")
            removed = mhr.merge(target, "house rules v2")
            text = target.read_text()
            self.assertGreater(removed, 0)
            self.assertEqual(text.count(mhr.BEGIN), 1)
            self.assertNotIn("OLD RULES body", text)

    def test_preserves_personal_content_above_legacy_block(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "CLAUDE.md"
            target.write_text(
                f"# My notes\n- keep this\n\n{mhr.LEGACY_HEADER}\n\nOLD stale rules\n"
            )
            mhr.merge(target, "house rules v2")
            text = target.read_text()
            self.assertIn("keep this", text)
            self.assertNotIn("OLD stale rules", text)
            self.assertEqual(text.count(mhr.BEGIN), 1)

    def test_no_legacy_returns_zero_removed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "CLAUDE.md"
            target.write_text("# My personal prefs\n- always use tabs\n")
            self.assertEqual(mhr.merge(target, "house rules v1"), 0)
            self.assertEqual(mhr.merge(target, "house rules v2"), 0)


if __name__ == "__main__":
    unittest.main()
