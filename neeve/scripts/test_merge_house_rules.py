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

    def test_user_content_after_legacy_block_survives(self) -> None:
        # The legacy strip must stop at the next top-level heading, not run
        # to the end of the region — otherwise a user's own content placed
        # after a legacy copy is silently destroyed.
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "CLAUDE.md"
            target.write_text(
                f"{mhr.LEGACY_HEADER}\n\nOLD RULES\n\n# My Own Heading\nkeep me\n"
            )
            removed = mhr.merge(target, "house rules v2")
            text = target.read_text()
            self.assertGreater(removed, 0)
            self.assertNotIn("OLD RULES", text)
            self.assertIn("# My Own Heading", text)
            self.assertIn("keep me", text)

    def test_legacy_header_must_match_whole_line(self) -> None:
        # A user who writes the exact legacy heading text as part of their
        # own content (not on its own line) must not trigger the strip.
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "CLAUDE.md"
            target.write_text(
                f"# My notes\nI still reference {mhr.LEGACY_HEADER} in prose.\nkeep this too\n"
            )
            removed = mhr.merge(target, "house rules v1")
            text = target.read_text()
            self.assertEqual(removed, 0)
            self.assertIn("keep this too", text)
            self.assertIn(f"I still reference {mhr.LEGACY_HEADER} in prose.", text)

    def test_writes_backup_before_destructive_edit(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "CLAUDE.md"
            original = "# My personal prefs\n- always use tabs\n"
            target.write_text(original)
            mhr.merge(target, "house rules v1")
            backup = target.with_name(target.name + ".bak")
            self.assertTrue(backup.is_file())
            self.assertEqual(backup.read_text(), original)

    def test_matches_legacy_header_across_crlf_line_endings(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "CLAUDE.md"
            target.write_text(f"{mhr.LEGACY_HEADER}\r\n\r\nOLD RULES\r\n")
            removed = mhr.merge(target, "house rules v2")
            text = target.read_text()
            self.assertGreater(removed, 0)
            self.assertNotIn("OLD RULES", text)

    def test_no_legacy_returns_zero_removed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "CLAUDE.md"
            target.write_text("# My personal prefs\n- always use tabs\n")
            self.assertEqual(mhr.merge(target, "house rules v1"), 0)
            self.assertEqual(mhr.merge(target, "house rules v2"), 0)


class CustomLabelTests(unittest.TestCase):
    """The repo-level Copilot-instructions call site: a different label, no
    legacy-stripping behavior (legacy_header=None — that label never had a
    pre-marker era to clean up after)."""

    LABEL = "NEEVE ROUTING GUIDE"

    def test_fresh_file_uses_custom_label_markers(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "copilot-instructions.md"
            mhr.merge(target, "routing table content", label=self.LABEL, legacy_header=None)
            text = target.read_text()
            self.assertIn(f"BEGIN {self.LABEL}", text)
            self.assertIn(f"END {self.LABEL}", text)
            self.assertIn("routing table content", text)

    def test_preserves_a_teams_existing_repo_instructions(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "copilot-instructions.md"
            target.write_text("# This repo's own Copilot conventions\n- use 2-space indent\n")
            mhr.merge(target, "routing table content", label=self.LABEL, legacy_header=None)
            text = target.read_text()
            self.assertIn("use 2-space indent", text)
            self.assertIn("routing table content", text)

    def test_rerun_updates_only_its_own_labeled_block(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "copilot-instructions.md"
            target.write_text("# Team conventions\n- stay off main\n")
            mhr.merge(target, "routing v1", label=self.LABEL, legacy_header=None)
            mhr.merge(target, "routing v2", label=self.LABEL, legacy_header=None)
            text = target.read_text()
            self.assertIn("stay off main", text)
            self.assertNotIn("routing v1", text)
            self.assertIn("routing v2", text)
            self.assertEqual(text.count(f"BEGIN {self.LABEL}"), 1)

    def test_default_label_house_rules_content_never_mistaken_for_custom_label(self) -> None:
        # Regression guard: a file that already has a default-label
        # (house-rules) block must not have a custom-label merge collide
        # with it — they're two independent managed blocks, coexisting.
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "combined.md"
            mhr.merge(target, "house rules content")  # default label
            mhr.merge(target, "routing content", label=self.LABEL, legacy_header=None)
            text = target.read_text()
            self.assertIn("house rules content", text)
            self.assertIn("routing content", text)
            self.assertEqual(text.count(mhr.BEGIN), 1)
            self.assertEqual(text.count(f"BEGIN {self.LABEL}"), 1)

    def test_legacy_header_none_does_not_write_backup(self) -> None:
        # This call site's target is COMMITTED into a product repo (see
        # module docstring) — an untracked `.bak` dropped there on every
        # init/re-init would be repo pollution, not a safety net, since
        # legacy_header=None means nothing destructive happens here.
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "copilot-instructions.md"
            target.write_text("# Team conventions\n- stay off main\n")
            mhr.merge(target, "routing content", label=self.LABEL, legacy_header=None)
            backup = target.with_name(target.name + ".bak")
            self.assertFalse(backup.exists())

    def test_legacy_header_none_does_not_touch_unrelated_house_rules_legacy_text(self) -> None:
        # If a file happens to contain the OLD house-rules legacy title for
        # some unrelated reason, a custom-label (legacy_header=None) merge
        # must not go looking for it and strip content it doesn't own.
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "copilot-instructions.md"
            target.write_text(f"{mhr.LEGACY_HEADER}\n\nsome unrelated content\n")
            removed = mhr.merge(target, "routing content", label=self.LABEL, legacy_header=None)
            self.assertEqual(removed, 0)
            text = target.read_text()
            self.assertIn("some unrelated content", text)


if __name__ == "__main__":
    unittest.main()
