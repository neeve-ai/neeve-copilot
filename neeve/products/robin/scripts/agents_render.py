#!/usr/bin/env python3
"""Render agents-src/<name>/AGENT.md into every tool's native agent format.

Same "one source, N rendered targets" pattern context_render.py already uses
for house rules — applied to a new asset type: agents. Three tools have a
real, working, global custom-agent mechanism today (Claude Code, GitHub
Copilot in VS Code, Codex CLI), each in an incompatible format; two (Cursor,
Antigravity) have none, so they get a Skill-shaped fallback package rendered
from the same source instead of a hand-duplicated second file.

Deliberately avoids a PyYAML dependency, same reasoning as context_render.py:
AGENT.md frontmatter uses a small, controlled subset (`name: value`,
`description: >` folded scalar with indented continuation lines, `tools:`
as one-per-line list items), so a hand-rolled parser keeps this runnable on
bare python3 with no `pip install` step.

Usage:
    agents_render.py <name> --claude OUTPUT_FILE
    agents_render.py <name> --copilot OUTPUT_FILE
    agents_render.py <name> --codex OUTPUT_FILE
    agents_render.py <name> --skill-fallback OUTPUT_DIR   # writes OUTPUT_DIR/<name>/SKILL.md
"""
from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # neeve/products/robin
AGENTS_SRC = ROOT / "agents-src"


@dataclass
class AgentSource:
    name: str
    description: str
    tools: list[str] = field(default_factory=list)
    body: str = ""


def _parse_frontmatter(text: str) -> tuple[dict, str]:
    """Parse AGENT.md's restricted frontmatter subset.

    Supports: `key: value`, `key: >` (folded scalar — indented continuation
    lines joined with single spaces), and `key:` followed by `  - item` list
    lines (used for `tools:`).
    """
    if not text.startswith("---\n"):
        raise ValueError("AGENT.md must start with a --- frontmatter block")
    _, _, rest = text.partition("---\n")
    fm_text, sep, body = rest.partition("\n---\n")
    if not sep:
        raise ValueError("AGENT.md frontmatter block is not closed with ---")
    body = body.lstrip("\n")

    data: dict = {}
    lines = fm_text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        i += 1
        if not line.strip():
            continue
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        key = key.strip()
        value = value.strip()
        if value == ">":
            parts = []
            while i < len(lines) and (lines[i].startswith(" ") or not lines[i].strip()):
                stripped = lines[i].strip()
                if stripped:
                    parts.append(stripped)
                i += 1
            data[key] = " ".join(parts)
        elif value == "":
            items = []
            while i < len(lines) and lines[i].strip().startswith("- "):
                items.append(lines[i].strip()[2:].strip())
                i += 1
            data[key] = items
        elif value.startswith('"') and value.endswith('"'):
            data[key] = value[1:-1]
        else:
            data[key] = value
    return data, body


def load_agent(name: str) -> AgentSource:
    path = AGENTS_SRC / name / "AGENT.md"
    if not path.is_file():
        print(f"No agent source file: {path}", file=sys.stderr)
        sys.exit(1)
    data, body = _parse_frontmatter(path.read_text())
    if not data.get("name") or not data.get("description"):
        print(f"{path} frontmatter must include non-empty name and description", file=sys.stderr)
        sys.exit(1)
    tools = data.get("tools") or []
    if isinstance(tools, str):
        tools = [t.strip() for t in tools.split(",") if t.strip()]
    return AgentSource(name=data["name"], description=data["description"], tools=tools, body=body)


def discover_agents() -> list[str]:
    if not AGENTS_SRC.is_dir():
        return []
    return sorted(p.name for p in AGENTS_SRC.iterdir() if p.is_dir() and (p / "AGENT.md").is_file())


# AGENT.md's `tools:` list is written once, in our own tool-agnostic
# vocabulary (read/write/search/bash) — each real tool has its own,
# incompatible tool-name vocabulary, confirmed directly against each tool's
# docs rather than assumed. A tools list that's merely copied verbatim into
# both `render_claude` and `render_copilot` looks plausible but is actually
# wrong in both places: neither `read`/`write`/`search`/`bash` are real
# Claude Code tool names (those are `Read`/`Write`/`Edit`/`Grep`/`Glob`/
# `Bash`, capitalized), and Copilot's VS Code tool vocabulary is a third,
# different set (`codebase`/`editFiles`/`search`/`runCommands`) confirmed via
# GitHub's own custom-agent docs. An unrecognized name in an explicit `tools:`
# allowlist silently yields zero usable tools in Claude Code — the agent can
# describe an action but never actually take it. Translate at render time so
# each target gets its own real names; fail loudly on an unmapped semantic
# name rather than let it silently disappear the same way again.
CLAUDE_TOOL_MAP: dict[str, list[str]] = {
    "read": ["Read"],
    "write": ["Write", "Edit"],
    "search": ["Grep", "Glob"],
    "bash": ["Bash"],
}

COPILOT_TOOL_MAP: dict[str, list[str]] = {
    "read": ["codebase"],
    "write": ["editFiles"],
    "search": ["search"],
    "bash": ["runCommands"],
}


def _translate_tools(tools: list[str], tool_map: dict[str, list[str]]) -> list[str]:
    translated: list[str] = []
    for tool in tools:
        try:
            translated.extend(tool_map[tool])
        except KeyError:
            raise ValueError(
                f"Unrecognized semantic tool name {tool!r} — add it to the tool map "
                "instead of letting it pass through untranslated and silently grant no tool."
            ) from None
    return translated


def _tools_yaml_block(tools: list[str]) -> str:
    if not tools:
        return ""
    return "tools:\n" + "\n".join(f"  - {t}" for t in tools) + "\n"


def render_claude(agent: AgentSource) -> str:
    """~/.claude/agents/<name>.md — real subagent, auto-triggers on description match."""
    fm = [
        "---",
        f"name: {agent.name}",
        "description: >",
        f"  {agent.description}",
    ]
    tools_block = _tools_yaml_block(_translate_tools(agent.tools, CLAUDE_TOOL_MAP))
    fm.append(tools_block.rstrip("\n") if tools_block else None)
    fm = [line for line in fm if line is not None]
    fm.append("---")
    return "\n".join(fm) + "\n\n" + agent.body.rstrip() + "\n"


def render_copilot(agent: AgentSource) -> str:
    """VS Code Copilot user-profile agents folder — .agent.md, picker-invoked."""
    fm = [
        "---",
        f"name: {agent.name}",
        "description: >",
        f"  {agent.description}",
        "target: vscode",
        "user-invocable: true",
    ]
    tools_block = _tools_yaml_block(_translate_tools(agent.tools, COPILOT_TOOL_MAP))
    if tools_block:
        fm.append(tools_block.rstrip("\n"))
    fm.append("---")
    return "\n".join(fm) + "\n\n" + agent.body.rstrip() + "\n"


def render_codex(agent: AgentSource) -> str:
    """~/.codex/agents/<name>.toml — explicit invocation only, via /agent.

    The multi-line `developer_instructions` field uses TOML's *literal*
    string form (`'''...'''`), not the basic (`\"\"\"...\"\"\"`) form —
    markdown bodies routinely contain backslashes (e.g. escaped code
    fences) and literal quote characters, both of which the basic form
    would try to interpret as escapes and fail on. The literal form
    processes no escapes at all; the only thing it can't contain is a
    literal `'''` sequence. The single-line `description` field uses a
    plain escaped basic string instead — English prose routinely contains
    apostrophes ("engineer's"), which would rule out TOML's literal form
    entirely; a basic string only needs `\\` and `"` escaped.
    """
    if "'''" in agent.body:
        raise ValueError(
            f"Agent body for {agent.name!r} contains a literal triple-single-quote, "
            "which breaks TOML's literal multi-line string syntax — rewrite it."
        )
    description = agent.description.replace("\\", "\\\\").replace('"', '\\"')
    lines = [
        f'name = "{agent.name}"',
        f'description = "{description}"',
        "developer_instructions = '''",
        agent.body.rstrip(),
        "'''",
    ]
    return "\n".join(lines) + "\n"


def render_skill_fallback(agent: AgentSource) -> str:
    """SKILL.md content for tools with no native agent concept (Cursor, Antigravity).

    Auto-triggers on description match, same as every other skill in this
    repo — in practice this is *more* automatic than Codex's explicit-only
    custom agents, not a downgrade.
    """
    fm = ["---", f"name: {agent.name}", "description: >", f"  {agent.description}", "---"]
    return "\n".join(fm) + "\n\n" + agent.body.rstrip() + "\n"


def cmd_write(agent_name: str, renderer, out_path: Path, is_skill_fallback: bool = False) -> int:
    agent = load_agent(agent_name)
    content = renderer(agent)
    if is_skill_fallback:
        out_path = out_path / agent.name / "SKILL.md"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(content)
    print(f"Wrote: {out_path}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("name", help="Agent name, matching agents-src/<name>/AGENT.md")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--claude", metavar="OUTPUT_FILE")
    mode.add_argument("--copilot", metavar="OUTPUT_FILE")
    mode.add_argument("--codex", metavar="OUTPUT_FILE")
    mode.add_argument("--skill-fallback", metavar="OUTPUT_DIR", help="Writes OUTPUT_DIR/<name>/SKILL.md")
    args = parser.parse_args()

    if args.claude:
        return cmd_write(args.name, render_claude, Path(args.claude).expanduser().resolve())
    if args.copilot:
        return cmd_write(args.name, render_copilot, Path(args.copilot).expanduser().resolve())
    if args.codex:
        return cmd_write(args.name, render_codex, Path(args.codex).expanduser().resolve())
    return cmd_write(
        args.name,
        render_skill_fallback,
        Path(args.skill_fallback).expanduser().resolve(),
        is_skill_fallback=True,
    )


if __name__ == "__main__":
    raise SystemExit(main())
