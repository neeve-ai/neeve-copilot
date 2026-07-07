#!/usr/bin/env python3
"""Tests for merge_session_hook.py — stdlib unittest only, no new dependency.

Run: python3 neeve/products/robin/scripts/test_merge_session_hook.py
"""
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import merge_session_hook as msh


class MergeSessionHookTests(unittest.TestCase):
    def test_fresh_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            msh.merge(target, "bash /a/b/refresh-context.sh /a/b", "refresh-context.sh")
            data = json.loads(target.read_text())
            entries = data["hooks"]["SessionStart"][0]["hooks"]
            self.assertEqual(len(entries), 1)
            self.assertEqual(entries[0]["command"], "bash /a/b/refresh-context.sh /a/b")
            self.assertEqual(data["hooks"]["SessionStart"][0]["matcher"], "startup")

    def test_preserves_existing_unrelated_settings(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            target.write_text(json.dumps({
                "permissionMode": "acceptEdits",
                "hooks": {
                    "SessionStart": [
                        {"matcher": "startup", "hooks": [{"type": "command", "command": "echo hi"}]}
                    ],
                    "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "guard.sh"}]}],
                },
            }))
            msh.merge(target, "bash /a/b/refresh-context.sh /a/b", "refresh-context.sh")
            data = json.loads(target.read_text())
            self.assertEqual(data["permissionMode"], "acceptEdits")
            self.assertIn("PreToolUse", data["hooks"])
            self.assertEqual(data["hooks"]["PreToolUse"][0]["hooks"][0]["command"], "guard.sh")
            # Our entry was appended alongside the existing "echo hi" one, in the
            # same "startup" matcher group, not a duplicate group.
            self.assertEqual(len(data["hooks"]["SessionStart"]), 1)
            commands = [h["command"] for h in data["hooks"]["SessionStart"][0]["hooks"]]
            self.assertIn("echo hi", commands)
            self.assertIn("bash /a/b/refresh-context.sh /a/b", commands)

    def test_rerun_replaces_in_place_without_duplicating(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            msh.merge(target, "bash /old/path/refresh-context.sh /old/path", "refresh-context.sh")
            msh.merge(target, "bash /new/path/refresh-context.sh /new/path", "refresh-context.sh")
            data = json.loads(target.read_text())
            entries = data["hooks"]["SessionStart"][0]["hooks"]
            self.assertEqual(len(entries), 1)
            self.assertEqual(entries[0]["command"], "bash /new/path/refresh-context.sh /new/path")

    def test_idempotent_rerun_same_command(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            for _ in range(3):
                msh.merge(target, "bash /a/b/refresh-context.sh /a/b", "refresh-context.sh")
            data = json.loads(target.read_text())
            entries = data["hooks"]["SessionStart"][0]["hooks"]
            self.assertEqual(len(entries), 1)

    def test_empty_file_treated_as_fresh(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            target.write_text("")
            msh.merge(target, "bash /a/b/refresh-context.sh /a/b", "refresh-context.sh")
            data = json.loads(target.read_text())
            self.assertEqual(len(data["hooks"]["SessionStart"]), 1)


if __name__ == "__main__":
    unittest.main()
