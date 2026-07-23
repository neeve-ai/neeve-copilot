#!/usr/bin/env python3
"""Tests for merge_default_agent.py — stdlib unittest only, no new dependency.

Run: python3 neeve/scripts/test_merge_default_agent.py
"""
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import merge_default_agent as mda


class MergeDefaultAgentTests(unittest.TestCase):
    def test_fresh_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.local.json"
            changed = mda.merge(target, "neeve")
            self.assertTrue(changed)
            data = json.loads(target.read_text())
            self.assertEqual(data["agent"], "neeve")

    def test_preserves_existing_unrelated_settings(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.local.json"
            target.write_text(json.dumps({"permissions": {"allow": ["Bash(git status)"]}}))
            mda.merge(target, "neeve")
            data = json.loads(target.read_text())
            self.assertEqual(data["agent"], "neeve")
            self.assertEqual(data["permissions"]["allow"], ["Bash(git status)"])

    def test_idempotent_rerun_reports_no_change(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.local.json"
            self.assertTrue(mda.merge(target, "neeve"))
            self.assertFalse(mda.merge(target, "neeve"))
            data = json.loads(target.read_text())
            self.assertEqual(data["agent"], "neeve")

    def test_switching_agent_updates_in_place(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.local.json"
            mda.merge(target, "neeve")
            changed = mda.merge(target, "other-agent")
            self.assertTrue(changed)
            data = json.loads(target.read_text())
            self.assertEqual(data["agent"], "other-agent")

    def test_never_touches_a_second_settings_file(self) -> None:
        # Regression guard: this script must only ever write the exact path
        # it's given — it has no business discovering or writing any other
        # settings.json on its own.
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.local.json"
            sibling = Path(tmp) / "settings.json"
            sibling.write_text("{}")
            mda.merge(target, "neeve")
            self.assertEqual(json.loads(sibling.read_text()), {})


if __name__ == "__main__":
    unittest.main()
