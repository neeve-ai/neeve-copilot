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


if __name__ == "__main__":
    unittest.main()
