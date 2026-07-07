#!/usr/bin/env python3
"""Tests for context_render.py — stdlib unittest only, no new dependency.

Run: python3 neeve/products/robin/scripts/test_context_render.py
"""
from __future__ import annotations

import re
import tempfile
import unittest
from pathlib import Path

import context_render as cr

PLACEHOLDER_RE = re.compile(r"\{\{[A-Z_]+\}\}")


class ParseSimpleYamlTests(unittest.TestCase):
    def test_scalars_bools_null(self) -> None:
        text = """
repo: robin-ai
spec_based_development: true
minimal: false
domain_extension: null
adr_source_of_truth: "the work-item tracker"
"""
        data = cr.parse_simple_yaml(text)
        self.assertEqual(data["repo"], "robin-ai")
        self.assertIs(data["spec_based_development"], True)
        self.assertIs(data["minimal"], False)
        self.assertIsNone(data["domain_extension"])
        self.assertEqual(data["adr_source_of_truth"], "the work-item tracker")

    def test_list_via_dash_lines(self) -> None:
        text = """
stack:
  - Python 3.12
  - FastAPI
do_not_modify: []
"""
        data = cr.parse_simple_yaml(text)
        self.assertEqual(data["stack"], ["Python 3.12", "FastAPI"])
        self.assertEqual(data["do_not_modify"], [])

    def test_comments_and_blank_lines_ignored(self) -> None:
        text = """
# a top-level comment
repo: robin-ai  # trailing comment

stack:
  - Python 3.12  # pinned
"""
        data = cr.parse_simple_yaml(text)
        self.assertEqual(data["repo"], "robin-ai")
        self.assertEqual(data["stack"], ["Python 3.12"])

    def test_list_item_with_no_preceding_key_raises(self) -> None:
        with self.assertRaises(ValueError):
            cr.parse_simple_yaml("- orphan item\n")

    def test_empty_value_starts_a_list_not_none(self) -> None:
        # Regression: setdefault(key, []).append(...) must not hit a None value.
        text = "do_not_modify:\n  - alembic/versions/\n"
        data = cr.parse_simple_yaml(text)
        self.assertEqual(data["do_not_modify"], ["alembic/versions/"])


class RenderBlockTests(unittest.TestCase):
    def test_stack_block_empty_input(self) -> None:
        self.assertEqual(cr.render_stack_block({}), "")

    def test_stack_block_with_stack_and_layers(self) -> None:
        out = cr.render_stack_block({"stack": ["Python 3.12"], "layers": ["domain"]})
        self.assertIn("### Stack", out)
        self.assertIn("Python 3.12", out)
        self.assertIn("### Repo Layout", out)

    def test_local_dev_block_empty_without_start_cmd(self) -> None:
        self.assertEqual(cr.render_local_dev_block({"local_dev_run_cmd": "make run"}), "")

    def test_local_dev_block_full(self) -> None:
        out = cr.render_local_dev_block(
            {
                "local_dev_start_cmd": "make dev-up",
                "local_dev_env_setup": "copy .env.example",
                "local_dev_services": ["postgres", "redis"],
            }
        )
        self.assertIn("**Start services:** make dev-up", out)
        self.assertIn("**Environment:** copy .env.example", out)
        self.assertIn("- postgres", out)

    def test_commands_block_empty(self) -> None:
        self.assertEqual(cr.render_commands_block({}), "")

    def test_do_not_modify_block_empty(self) -> None:
        self.assertEqual(cr.render_do_not_modify_block({}), "")

    def test_do_not_modify_block_present(self) -> None:
        out = cr.render_do_not_modify_block({"do_not_modify": ["alembic/versions/"]})
        self.assertIn("## Do Not Modify Without Discussion", out)
        self.assertIn("alembic/versions/", out)


class ProductOverviewTests(unittest.TestCase):
    def test_product_repo_table_has_a_row_per_registered_repo(self) -> None:
        table = cr.render_product_repo_table()
        repo_files = list(cr.REPOS_DIR.glob("*.yaml"))
        for repo_yaml in repo_files:
            v = cr.parse_simple_yaml(repo_yaml.read_text())
            self.assertIn(f"`{v['repo']}`", table)

    def test_product_overview_fragment_substitutes_table_placeholder(self) -> None:
        out = cr.render_product_overview_fragment()
        self.assertNotIn("{{PRODUCT_REPO_TABLE}}", out)
        self.assertIn("Repos in this product", out)


class FragmentGatingTests(unittest.TestCase):
    def test_spec_review_fragment_off_by_default(self) -> None:
        self.assertEqual(cr.render_spec_review_fragment({}), "")

    def test_spec_review_fragment_on(self) -> None:
        out = cr.render_spec_review_fragment({"spec_based_development": True})
        self.assertNotEqual(out, "")
        self.assertNotIn("{{ADR_SOURCE_OF_TRUTH}}", out)
        self.assertNotIn("{{SPEC_WIKI_REF_SHORT}}", out)
        self.assertNotIn("{{SOURCE_ROOT}}", out)

    def test_ot_domain_fragment_gated(self) -> None:
        self.assertEqual(cr.render_ot_domain_fragment({}), "")
        self.assertEqual(cr.render_ot_domain_fragment({"domain_extension": "something-else"}), "")
        out = cr.render_ot_domain_fragment({"domain_extension": "ot-building-automation"})
        self.assertNotEqual(out, "")

    def test_dls_fragment_gated(self) -> None:
        self.assertEqual(cr.render_dls_fragment({}), "")
        self.assertEqual(cr.render_dls_fragment({"dls_extension": False}), "")
        out = cr.render_dls_fragment({"dls_extension": True})
        self.assertNotEqual(out, "")

    def test_production_consequence_fragment_always_present(self) -> None:
        out = cr.render_production_consequence_fragment()
        self.assertIn("Required in Every Output: Consequence and Gaps", out)


class HouseRulesTests(unittest.TestCase):
    """The user-level global instructions variant: no repo-specific facts,
    no unrendered placeholders, no leftover conditional-fragment markers."""

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


class RenderNoPlaceholderLeakTests(unittest.TestCase):
    """Regression guard: every {{PLACEHOLDER}} in base.md must be replaced for
    every registered repo. This is the test that would have caught a newly
    added placeholder silently failing to render (e.g. the Production
    Consequence fragment shipping without a matching .replace() call)."""

    def test_base_md_placeholders_all_get_a_replace_call(self) -> None:
        base_text = cr.BASE_MD.read_text()
        placeholders_in_template = set(PLACEHOLDER_RE.findall(base_text))
        self.assertTrue(placeholders_in_template, "base.md should contain at least one {{PLACEHOLDER}}")
        # Every repo yaml should render with zero of these placeholders surviving.
        repo_files = sorted(cr.REPOS_DIR.glob("*.yaml"))
        self.assertTrue(repo_files, "expected at least one context-src/repos/*.yaml fixture")
        for repo_yaml in repo_files:
            repo = repo_yaml.stem
            with self.subTest(repo=repo):
                outputs = cr.render(repo)
                for rel_path, content in outputs.items():
                    leaked = PLACEHOLDER_RE.findall(content)
                    self.assertEqual(
                        leaked, [], f"{repo}:{rel_path} leaked unrendered placeholders: {leaked}"
                    )

    def test_minimal_repo_renders_without_crashing(self) -> None:
        minimal_repos = [
            p.stem
            for p in cr.REPOS_DIR.glob("*.yaml")
            if cr.load_repo_vars(p.stem).get("minimal")
        ]
        self.assertTrue(minimal_repos, "expected at least one minimal:true fixture repo")
        for repo in minimal_repos:
            with self.subTest(repo=repo):
                outputs = cr.render(repo)
                for content in outputs.values():
                    self.assertIn("minimal-governance", content)
                    self.assertEqual(PLACEHOLDER_RE.findall(content), [])

    def test_all_four_output_files_identical(self) -> None:
        # The four always-on files are meant to carry byte-identical content.
        any_repo = next(iter(sorted(p.stem for p in cr.REPOS_DIR.glob("*.yaml"))))
        outputs = cr.render(any_repo)
        contents = list(outputs.values())
        self.assertTrue(all(c == contents[0] for c in contents))


class WriteAndCheckRoundTripTests(unittest.TestCase):
    def test_write_then_check_reports_clean(self) -> None:
        any_repo = next(iter(sorted(p.stem for p in cr.REPOS_DIR.glob("*.yaml"))))
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp)
            rc_write = cr.cmd_write(any_repo, target)
            self.assertEqual(rc_write, 0)
            rc_check = cr.cmd_check(any_repo, target)
            self.assertEqual(rc_check, 0)

    def test_check_reports_drift_on_hand_edit(self) -> None:
        any_repo = next(iter(sorted(p.stem for p in cr.REPOS_DIR.glob("*.yaml"))))
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp)
            cr.cmd_write(any_repo, target)
            (target / "AGENTS.md").write_text("hand-edited, should be flagged as drift\n")
            rc_check = cr.cmd_check(any_repo, target)
            self.assertEqual(rc_check, 1)


if __name__ == "__main__":
    unittest.main()
