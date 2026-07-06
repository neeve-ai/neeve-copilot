#!/usr/bin/env python3
"""Tests for context_sync.py — stdlib unittest only, no new dependency.

Run: python3 neeve/products/robin/scripts/test_context_sync.py
"""
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import context_sync as cs


class ContextSyncTests(unittest.TestCase):
    def test_fresh_target_gets_instructions_and_prompts(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp)
            v = cs.cr.load_repo_vars("robin-kb-service")
            v["repo"] = "robin-kb-service"
            changed = cs.sync_instructions(v, target) + cs.sync_prompts(target)
            self.assertIn("AGENTS.md", changed)
            self.assertTrue((target / "AGENTS.md").is_file())
            self.assertTrue((target / ".github" / "prompts" / "to-spec.prompt.md").is_file())

    def test_second_run_is_a_no_op(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp)
            v = cs.cr.load_repo_vars("robin-kb-service")
            v["repo"] = "robin-kb-service"
            cs.sync_instructions(v, target)
            cs.sync_prompts(target)
            # Second pass against the now-synced target: nothing left to change.
            changed_again = cs.sync_instructions(v, target) + cs.sync_prompts(target)
            self.assertEqual(changed_again, [])

    def test_hooks_only_sync_for_spec_based_development_repos(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp)
            v = cs.cr.load_repo_vars("robin-kb-service")  # spec_based_development: false
            v["repo"] = "robin-kb-service"
            changed = cs.sync_hooks(v, target)
            self.assertEqual(changed, [])

            v2 = cs.cr.load_repo_vars("robin-ai")  # spec_based_development: true
            v2["repo"] = "robin-ai"
            changed2 = cs.sync_hooks(v2, target)
            self.assertIn(".github/hooks/hooks.json", changed2)

    def test_project_skill_only_syncs_for_ot_domain_repos(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp)
            v = cs.cr.load_repo_vars("robin-kb-service")
            v["repo"] = "robin-kb-service"
            self.assertEqual(cs.sync_project_skill(v, target), [])

            v2 = cs.cr.load_repo_vars("alc-hello-addon")
            v2["repo"] = "alc-hello-addon"
            changed = cs.sync_project_skill(v2, target)
            self.assertIn(".github/skills/ot-building-automation/SKILL.md", changed)

    def test_main_prints_no_change_on_second_run(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            import subprocess
            import sys

            script = str(Path(__file__).parent / "context_sync.py")
            first = subprocess.run(
                [sys.executable, script, "robin-kb-service", tmp], capture_output=True, text=True
            )
            self.assertIn("CHANGED", first.stdout)
            second = subprocess.run(
                [sys.executable, script, "robin-kb-service", tmp], capture_output=True, text=True
            )
            self.assertEqual(second.stdout.strip(), "NO_CHANGE")


if __name__ == "__main__":
    unittest.main()
