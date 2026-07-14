#!/usr/bin/env python3
"""Tests for context_render.py — stdlib unittest only, no new dependency.

Run: python3 neeve/scripts/test_context_render.py
"""
from __future__ import annotations

import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import context_render as cr

PLACEHOLDER_RE = re.compile(r"\{\{[A-Z_]+\}\}")


class ProductOverviewTests(unittest.TestCase):
    def test_product_overview_fragment_has_static_repo_table(self) -> None:
        out = cr.render_product_overview_fragment()
        self.assertNotIn("{{PRODUCT_REPO_TABLE}}", out)
        self.assertIn("Repos in this product", out)
        self.assertIn("`robin-ai`", out)
        self.assertIn("`robin-web`", out)


class FragmentTests(unittest.TestCase):
    def test_spec_review_fragment_renders(self) -> None:
        out = cr.render_spec_review_fragment()
        self.assertNotEqual(out, "")

    def test_ot_domain_fragment_renders(self) -> None:
        out = cr.render_ot_domain_fragment()
        self.assertNotEqual(out, "")

    def test_dls_fragment_renders(self) -> None:
        out = cr.render_dls_fragment()
        self.assertNotEqual(out, "")

    def test_production_consequence_fragment_present(self) -> None:
        out = cr.render_production_consequence_fragment()
        self.assertIn("Required in Every Output: Consequence and Gaps", out)


class HouseRulesTests(unittest.TestCase):
    def test_no_placeholders_leak(self) -> None:
        out = cr.render_house_rules()
        self.assertEqual(PLACEHOLDER_RE.findall(out), [])

    def test_no_repo_specific_section(self) -> None:
        out = cr.render_house_rules()
        self.assertNotIn("## This Repo", out)

    def test_universal_content_present(self) -> None:
        out = cr.render_house_rules()
        self.assertIn("Zero-trust by default", out)
        self.assertIn("Required in Every Output: Consequence and Gaps", out)
        self.assertIn("Product Overview: Robin", out)
        self.assertIn("Skills Available", out)

    def test_cli_writes_output(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "house-rules.md"
            result = subprocess.run(
                [
                    sys.executable,
                    str(Path(__file__).resolve().with_name("context_render.py")),
                    "--house-rules",
                    str(target),
                ],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(target.is_file())
            self.assertIn("Neeve Engineering — House Rules", target.read_text())


if __name__ == "__main__":
    unittest.main()
