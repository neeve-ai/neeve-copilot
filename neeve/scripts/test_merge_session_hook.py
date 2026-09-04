#!/usr/bin/env python3
"""Tests for merge_session_hook.py — stdlib unittest only, no new dependency.

Run: python3 neeve/scripts/test_merge_session_hook.py
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

    def test_remove_removes_hook_and_preserves_other_keys(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            original = {
                "permissionMode": "acceptEdits",
                "hooks": {
                    "SessionStart": [
                        {
                            "matcher": "startup",
                            "hooks": [
                                {"type": "command", "command": "echo hi"},
                                {"type": "command", "command": "bash /a/b/refresh-context.sh /a/b"},
                            ],
                        }
                    ],
                    "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "guard.sh"}]}],
                },
            }
            target.write_text(json.dumps(original))
            removed = msh.remove(target, "refresh-context.sh")
            self.assertTrue(removed)
            data = json.loads(target.read_text())
            self.assertEqual(data["permissionMode"], "acceptEdits")
            self.assertEqual(data["hooks"]["PreToolUse"], original["hooks"]["PreToolUse"])
            commands = [h["command"] for h in data["hooks"]["SessionStart"][0]["hooks"]]
            self.assertEqual(commands, ["echo hi"])

    def test_remove_drops_now_empty_matcher_group(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            target.write_text(json.dumps({
                "hooks": {
                    "SessionStart": [
                        {"matcher": "startup", "hooks": [{"type": "command", "command": "bash /a/b/refresh-context.sh /a/b"}]}
                    ],
                },
            }))
            removed = msh.remove(target, "refresh-context.sh")
            self.assertTrue(removed)
            data = json.loads(target.read_text())
            self.assertNotIn("hooks", data)

    def test_remove_is_idempotent(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            target.write_text(json.dumps({
                "permissionMode": "acceptEdits",
                "hooks": {
                    "SessionStart": [
                        {"matcher": "startup", "hooks": [{"type": "command", "command": "bash /a/b/refresh-context.sh /a/b"}]}
                    ],
                },
            }))
            self.assertTrue(msh.remove(target, "refresh-context.sh"))
            after_first = target.read_text()
            self.assertFalse(msh.remove(target, "refresh-context.sh"))
            self.assertEqual(target.read_text(), after_first)

    def test_remove_no_op_when_hook_absent(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            original_text = json.dumps({"permissionMode": "acceptEdits"})
            target.write_text(original_text)
            removed = msh.remove(target, "refresh-context.sh")
            self.assertFalse(removed)
            self.assertEqual(target.read_text(), original_text)

    def test_remove_no_op_when_file_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            removed = msh.remove(target, "refresh-context.sh")
            self.assertFalse(removed)
            self.assertFalse(target.exists())


if __name__ == "__main__":
    unittest.main()
