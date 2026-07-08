#!/usr/bin/env python3
"""Tests for agents_render.py — stdlib unittest only, no new dependency.

Run: python3 neeve/products/robin/scripts/test_agents_render.py
"""
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import agents_render as ar

SAMPLE_AGENT_MD = """---
name: sample-agent
description: >
  Turns a problem statement into a thing. Trigger on: "make a thing",
  "write me a thing".
tools:
  - read
  - write
---

# Sample Agent

## Producer Contract

- Must hand off a stable slug.

## Workflow

1. Do the thing.
"""


class ParseFrontmatterTests(unittest.TestCase):
    def test_parses_name_description_tools_and_body(self) -> None:
        data, body = ar._parse_frontmatter(SAMPLE_AGENT_MD)
        self.assertEqual(data["name"], "sample-agent")
        self.assertIn("Turns a problem statement", data["description"])
        self.assertIn('"make a thing"', data["description"])
        self.assertEqual(data["tools"], ["read", "write"])
        self.assertTrue(body.startswith("# Sample Agent"))
        self.assertIn("## Producer Contract", body)

    def test_missing_closing_delimiter_raises(self) -> None:
        with self.assertRaises(ValueError):
            ar._parse_frontmatter("---\nname: x\n")

    def test_requires_leading_frontmatter(self) -> None:
        with self.assertRaises(ValueError):
            ar._parse_frontmatter("# no frontmatter here\n")


class LoadAgentTests(unittest.TestCase):
    def test_load_agent_from_fixture_dir(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            src_dir = Path(tmp) / "agents-src"
            (src_dir / "sample-agent").mkdir(parents=True)
            (src_dir / "sample-agent" / "AGENT.md").write_text(SAMPLE_AGENT_MD)

            original = ar.AGENTS_SRC
            ar.AGENTS_SRC = src_dir
            try:
                agent = ar.load_agent("sample-agent")
            finally:
                ar.AGENTS_SRC = original

            self.assertEqual(agent.name, "sample-agent")
            self.assertEqual(agent.tools, ["read", "write"])
            self.assertIn("## Workflow", agent.body)


class RenderTargetTests(unittest.TestCase):
    def setUp(self) -> None:
        self.agent = ar.AgentSource(
            name="sample-agent",
            description="Turns a problem statement into a thing.",
            tools=["read", "write"],
            body="# Sample Agent\n\n## Workflow\n\n1. Do the thing.\n",
        )

    def test_claude_render_has_frontmatter_and_body(self) -> None:
        out = ar.render_claude(self.agent)
        self.assertTrue(out.startswith("---\n"))
        self.assertIn("name: sample-agent", out)
        self.assertIn("description: >", out)
        # Semantic "read"/"write" translate to Claude Code's real,
        # capitalized tool names — not passed through verbatim.
        self.assertIn("tools:\n  - Read\n  - Write\n  - Edit", out)
        self.assertIn("## Workflow", out)

    def test_copilot_render_has_target_and_user_invocable(self) -> None:
        out = ar.render_copilot(self.agent)
        self.assertIn("target: vscode", out)
        self.assertIn("user-invocable: true", out)
        # Copilot's VS Code tool vocabulary is a third, different set —
        # "write" maps to "editFiles", not Claude's "Write, Edit".
        self.assertIn("tools:\n  - codebase\n  - editFiles", out)
        self.assertIn("## Workflow", out)

    def test_codex_render_is_valid_toml(self) -> None:
        out = ar.render_codex(self.agent)
        self.assertIn('name = "sample-agent"', out)
        self.assertIn("developer_instructions = '''", out)
        self.assertIn("## Workflow", out)
        try:
            import tomllib

            parsed = tomllib.loads(out)
            self.assertEqual(parsed["name"], "sample-agent")
            self.assertIn("## Workflow", parsed["developer_instructions"])
        except ImportError:
            pass  # tomllib is 3.11+; skip strict parse on older interpreters.

    def test_codex_render_rejects_triple_single_quote_in_body(self) -> None:
        bad_agent = ar.AgentSource(
            name="x", description="d", tools=[], body="body with a literal ''' inside"
        )
        with self.assertRaises(ValueError):
            ar.render_codex(bad_agent)

    def test_codex_render_handles_apostrophe_and_backslash_in_description(self) -> None:
        """Description uses an escaped TOML basic string precisely so
        ordinary prose apostrophes ("engineer's") don't have to be banned
        the way they would under TOML's literal-string form."""
        agent = ar.AgentSource(
            name="x",
            description='an engineer\'s PRD with a backslash \\ inside',
            tools=[],
            body="body",
        )
        out = ar.render_codex(agent)
        import tomllib

        parsed = tomllib.loads(out)
        self.assertEqual(parsed["description"], "an engineer's PRD with a backslash \\ inside")

    def test_codex_render_handles_backslashes_and_triple_double_quotes_in_body(self) -> None:
        """The literal '''...''' TOML form must survive content a basic
        \"\"\"...\"\"\" form would choke on — this is a regression test for
        a real bug: escaped mermaid code fences (containing backslashes)
        broke the original basic-string implementation."""
        agent = ar.AgentSource(
            name="x",
            description="d",
            tools=[],
            body='line with a backslash \\ and a literal """ triple-double-quote',
        )
        out = ar.render_codex(agent)
        import tomllib

        parsed = tomllib.loads(out)
        self.assertIn("a backslash \\", parsed["developer_instructions"])
        self.assertIn('"""', parsed["developer_instructions"])

    def test_skill_fallback_render_has_no_tool_specific_fields(self) -> None:
        out = ar.render_skill_fallback(self.agent)
        self.assertIn("name: sample-agent", out)
        self.assertNotIn("target: vscode", out)
        self.assertNotIn("developer_instructions", out)
        self.assertIn("## Workflow", out)

    def test_body_identical_across_all_render_targets(self) -> None:
        """Single source, not forked: the body markdown must be byte-identical
        in every rendered form, only the frontmatter wrapper differs."""
        body = self.agent.body.rstrip()
        for out in (
            ar.render_claude(self.agent),
            ar.render_copilot(self.agent),
            ar.render_skill_fallback(self.agent),
        ):
            self.assertIn(body, out)
        self.assertIn(body, ar.render_codex(self.agent))


class ToolTranslationTests(unittest.TestCase):
    def test_claude_map_covers_every_semantic_tool_used_by_real_agents(self) -> None:
        for semantic in ("read", "write", "search", "bash"):
            self.assertIn(semantic, ar.CLAUDE_TOOL_MAP)
            self.assertIn(semantic, ar.COPILOT_TOOL_MAP)

    def test_search_translates_to_grep_and_glob_for_claude(self) -> None:
        self.assertEqual(ar._translate_tools(["search"], ar.CLAUDE_TOOL_MAP), ["Grep", "Glob"])

    def test_search_translates_to_single_search_tool_for_copilot(self) -> None:
        self.assertEqual(ar._translate_tools(["search"], ar.COPILOT_TOOL_MAP), ["search"])

    def test_unrecognized_semantic_tool_raises_instead_of_silently_dropping(self) -> None:
        with self.assertRaises(ValueError):
            ar._translate_tools(["not-a-real-tool"], ar.CLAUDE_TOOL_MAP)

    def test_every_real_agent_source_uses_only_mapped_semantic_tool_names(self) -> None:
        """Regression guard for the actual bug found in production: every
        agents-src/*/AGENT.md tools: entry must be a key this module knows
        how to translate for both Claude and Copilot, not a name that
        silently earns the agent zero real tools in either one."""
        for name in ar.discover_agents():
            agent = ar.load_agent(name)
            for tool in agent.tools:
                self.assertIn(tool, ar.CLAUDE_TOOL_MAP, f"{name}: unmapped tool {tool!r}")
                self.assertIn(tool, ar.COPILOT_TOOL_MAP, f"{name}: unmapped tool {tool!r}")


class DiscoverAgentsTests(unittest.TestCase):
    def test_discovers_only_dirs_with_agent_md(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            src_dir = Path(tmp) / "agents-src"
            (src_dir / "has-agent").mkdir(parents=True)
            (src_dir / "has-agent" / "AGENT.md").write_text(SAMPLE_AGENT_MD)
            (src_dir / "no-agent-file").mkdir(parents=True)

            original = ar.AGENTS_SRC
            ar.AGENTS_SRC = src_dir
            try:
                found = ar.discover_agents()
            finally:
                ar.AGENTS_SRC = original

            self.assertEqual(found, ["has-agent"])

    def test_empty_dir_returns_empty_list(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            original = ar.AGENTS_SRC
            ar.AGENTS_SRC = Path(tmp) / "does-not-exist"
            try:
                self.assertEqual(ar.discover_agents(), [])
            finally:
                ar.AGENTS_SRC = original


if __name__ == "__main__":
    unittest.main()
