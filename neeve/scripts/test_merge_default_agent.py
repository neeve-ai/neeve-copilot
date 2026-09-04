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


class OnlyIfUnsetModeTests(unittest.TestCase):
    """The mode install.sh uses globally: set the default exactly once, and
    never touch a value an engineer has already set — including if they set
    it to neeve themselves, to a different agent, or explicitly cleared it."""

    def test_sets_on_fresh_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            changed = mda.merge(target, "neeve", only_if_unset=True)
            self.assertTrue(changed)
            self.assertEqual(json.loads(target.read_text())["agent"], "neeve")

    def test_does_not_override_a_different_existing_agent(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            target.write_text(json.dumps({"agent": "code-reviewer"}))
            changed = mda.merge(target, "neeve", only_if_unset=True)
            self.assertFalse(changed)
            self.assertEqual(json.loads(target.read_text())["agent"], "code-reviewer")

    def test_does_not_touch_an_explicit_null_opt_out(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            target.write_text(json.dumps({"agent": None}))
            changed = mda.merge(target, "neeve", only_if_unset=True)
            self.assertFalse(changed)
            self.assertIsNone(json.loads(target.read_text())["agent"])

    def test_second_sync_run_is_a_pure_no_op_once_set(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            self.assertTrue(mda.merge(target, "neeve", only_if_unset=True))
            # Simulate the engineer then deliberately switching agents...
            data = json.loads(target.read_text())
            data["agent"] = "their-own-custom-agent"
            target.write_text(json.dumps(data))
            # ...a later sync_skills.sh run must not stomp that back to neeve.
            changed = mda.merge(target, "neeve", only_if_unset=True)
            self.assertFalse(changed)
            self.assertEqual(json.loads(target.read_text())["agent"], "their-own-custom-agent")

    def test_preserves_unrelated_settings_when_setting_default(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            target.write_text(json.dumps({"model": "sonnet", "hooks": {"SessionStart": []}}))
            mda.merge(target, "neeve", only_if_unset=True)
            data = json.loads(target.read_text())
            self.assertEqual(data["agent"], "neeve")
            self.assertEqual(data["model"], "sonnet")
            self.assertEqual(data["hooks"], {"SessionStart": []})


class UpgradeFromModeTests(unittest.TestCase):
    """The forward-migration path: correct a known-stale `agent` value
    without touching a file where it's unset, current, or a deliberate
    engineer override."""

    def test_rewrites_when_current_value_matches_old_value(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            target.write_text(json.dumps({"agent": "old-name"}))
            changed = mda.merge(target, "neeve", upgrade_from="old-name")
            self.assertTrue(changed)
            self.assertEqual(json.loads(target.read_text())["agent"], "neeve")

    def test_no_ops_when_current_value_differs_from_old_value(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            target.write_text(json.dumps({"agent": "their-own-custom-agent"}))
            changed = mda.merge(target, "neeve", upgrade_from="old-name")
            self.assertFalse(changed)
            self.assertEqual(json.loads(target.read_text())["agent"], "their-own-custom-agent")

    def test_no_ops_when_key_is_unset(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            changed = mda.merge(target, "neeve", upgrade_from="old-name")
            self.assertFalse(changed)
            self.assertFalse(target.exists())

    def test_respects_a_deliberate_null_opt_out(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            target.write_text(json.dumps({"agent": None}))
            changed = mda.merge(target, "neeve", upgrade_from="old-name")
            self.assertFalse(changed)
            self.assertIsNone(json.loads(target.read_text())["agent"])

    def test_respects_a_deliberate_empty_string_opt_out(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            target.write_text(json.dumps({"agent": ""}))
            changed = mda.merge(target, "neeve", upgrade_from="old-name")
            self.assertFalse(changed)
            self.assertEqual(json.loads(target.read_text())["agent"], "")

    def test_preserves_unrelated_settings_on_upgrade(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            target.write_text(json.dumps({"agent": "old-name", "model": "sonnet"}))
            mda.merge(target, "neeve", upgrade_from="old-name")
            data = json.loads(target.read_text())
            self.assertEqual(data["agent"], "neeve")
            self.assertEqual(data["model"], "sonnet")


class CliUpgradeFromFlagTests(unittest.TestCase):
    def test_flag_parsing_rewrites_on_matching_old_value(self) -> None:
        import subprocess
        import sys as _sys

        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            target.write_text(json.dumps({"agent": "old-name"}))
            result = subprocess.run(
                [_sys.executable, str(Path(__file__).parent / "merge_default_agent.py"),
                 str(target), "neeve", "--upgrade-from", "old-name"],
                capture_output=True, text=True, check=True,
            )
            self.assertIn("Wrote", result.stdout)
            self.assertEqual(json.loads(target.read_text())["agent"], "neeve")

    def test_flag_parsing_leaves_non_matching_value_untouched(self) -> None:
        import subprocess
        import sys as _sys

        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            target.write_text(json.dumps({"agent": "their-own-custom-agent"}))
            result = subprocess.run(
                [_sys.executable, str(Path(__file__).parent / "merge_default_agent.py"),
                 str(target), "neeve", "--upgrade-from", "old-name"],
                capture_output=True, text=True, check=True,
            )
            self.assertIn("left as-is", result.stdout)
            self.assertEqual(json.loads(target.read_text())["agent"], "their-own-custom-agent")

    def test_only_if_unset_and_upgrade_from_together_is_rejected(self) -> None:
        import subprocess
        import sys as _sys

        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            result = subprocess.run(
                [_sys.executable, str(Path(__file__).parent / "merge_default_agent.py"),
                 str(target), "neeve", "--only-if-unset", "--upgrade-from", "old-name"],
                capture_output=True, text=True,
            )
            self.assertNotEqual(result.returncode, 0)


class CliOnlyIfUnsetFlagTests(unittest.TestCase):
    def test_flag_parsing_extracts_only_if_unset_and_two_positional_args(self) -> None:
        import subprocess
        import sys as _sys

        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "settings.json"
            target.write_text(json.dumps({"agent": "existing"}))
            result = subprocess.run(
                [_sys.executable, str(Path(__file__).parent / "merge_default_agent.py"),
                 str(target), "neeve", "--only-if-unset"],
                capture_output=True, text=True, check=True,
            )
            self.assertIn("left as-is", result.stdout)
            self.assertEqual(json.loads(target.read_text())["agent"], "existing")


if __name__ == "__main__":
    unittest.main()
