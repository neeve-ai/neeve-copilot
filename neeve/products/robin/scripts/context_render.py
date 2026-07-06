#!/usr/bin/env python3
"""Render context-src/base.md + per-repo YAML into a repo's always-on context files.

Deliberately avoids a PyYAML dependency: the repo variable files use a small,
controlled YAML subset (scalars, null, booleans, one level of string lists),
so a minimal hand-rolled parser keeps this runnable on a bare python3 with no
`pip install` step for anyone on the team.

Usage:
    context_render.py <repo> --check   # diff rendered output against the target repo's committed files
    context_render.py <repo> --write <target-repo-path>  # write rendered output into a checkout
"""
from __future__ import annotations

import argparse
import difflib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # neeve/products/robin
CONTEXT_SRC = ROOT / "context-src"
BASE_MD = CONTEXT_SRC / "base.md"
FRAGMENTS_DIR = CONTEXT_SRC / "fragments"
REPOS_DIR = CONTEXT_SRC / "repos"

OUTPUT_FILES = ["AGENTS.md", ".github/copilot-instructions.md", "CLAUDE.md", ".cursorrules"]


def parse_simple_yaml(text: str) -> dict:
    """Parse the restricted YAML subset used by context-src/repos/*.yaml."""
    data: dict = {}
    lines = text.splitlines()
    i = 0
    current_list_key = None
    while i < len(lines):
        raw = lines[i]
        i += 1
        line = raw.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        if line.startswith("  - ") or line.startswith("- "):
            if current_list_key is None:
                raise ValueError(f"List item with no preceding key: {raw!r}")
            item = line.strip()[2:].strip().strip('"')
            data.setdefault(current_list_key, []).append(item)
            continue
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        key = key.strip()
        value = value.strip()
        if value == "" or value == "[]":
            # Empty value: either "key:" starting a following list, or an
            # explicit empty list "key: []". Both are represented as [].
            data[key] = []
            current_list_key = key if value == "" else None
            continue
        current_list_key = None
        if value == "null" or value == "~":
            data[key] = None
        elif value in ("true", "True"):
            data[key] = True
        elif value in ("false", "False"):
            data[key] = False
        elif value.startswith('"') and value.endswith('"'):
            data[key] = value[1:-1]
        else:
            data[key] = value
    return data


def load_repo_vars(repo: str) -> dict:
    path = REPOS_DIR / f"{repo}.yaml"
    if not path.is_file():
        print(f"No repo variables file: {path}", file=sys.stderr)
        sys.exit(1)
    return parse_simple_yaml(path.read_text())


def bullet_block(heading: str, items: list[str] | None) -> str:
    if not items:
        return ""
    body = "\n".join(f"- {item}" for item in items)
    return f"### {heading}\n\n{body}\n"


def render_stack_block(v: dict) -> str:
    parts = []
    stack = v.get("stack") or []
    if stack:
        parts.append(bullet_block("Stack", stack))
    layers = v.get("layers") or []
    if layers:
        parts.append(bullet_block("Repo Layout", layers))
    return "\n".join(p for p in parts if p).strip()


def render_local_dev_block(v: dict) -> str:
    if not v.get("local_dev_start_cmd"):
        return ""
    lines = ["### Running Locally", ""]
    if v.get("local_dev_env_setup"):
        lines.append(f"**Environment:** {v['local_dev_env_setup']}")
        lines.append("")
    if v.get("local_dev_start_cmd"):
        lines.append(f"**Start services:** {v['local_dev_start_cmd']}")
        lines.append("")
    if v.get("local_dev_run_cmd"):
        lines.append(f"**Run the app:** {v['local_dev_run_cmd']}")
        lines.append("")
    if v.get("local_dev_db_cmd"):
        lines.append(f"**Database:** {v['local_dev_db_cmd']}")
        lines.append("")
    if v.get("local_dev_status_cmd"):
        lines.append(f"**Status / logs:** {v['local_dev_status_cmd']}")
        lines.append("")
    if v.get("local_dev_stop_cmd"):
        lines.append(f"**Stop services:** {v['local_dev_stop_cmd']}")
        lines.append("")
    services = v.get("local_dev_services") or []
    if services:
        lines.append("**Services once started:**")
        lines.append("")
        lines.extend(f"- {s}" for s in services)
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def render_commands_block(v: dict) -> str:
    test_cmd = v.get("test_cmd")
    lint_cmd = v.get("lint_cmd")
    if not test_cmd and not lint_cmd:
        return ""
    lines = ["### This Repo's Commands", ""]
    if lint_cmd:
        lines.append(f"```bash\n{lint_cmd}\n```")
    if test_cmd:
        lines.append(f"```bash\n{test_cmd}\n```")
    return "\n".join(lines)


def render_do_not_modify_block(v: dict) -> str:
    items = v.get("do_not_modify") or []
    if not items:
        return ""
    return "## Do Not Modify Without Discussion\n\n" + "\n".join(f"- {item}" for item in items)


def render_spec_review_fragment(v: dict) -> str:
    if not v.get("spec_based_development"):
        return ""
    text = (FRAGMENTS_DIR / "spec-review-checklist.md").read_text()
    text = text.replace("{{ADR_SOURCE_OF_TRUTH}}", v.get("adr_source_of_truth") or "the team's work-item tracker")
    text = text.replace("{{SPEC_WIKI_REF}}", v.get("spec_wiki_ref") or "")
    text = text.replace("{{SPEC_WIKI_REF_SHORT}}", v.get("spec_wiki_ref_short") or "the team's Spec-Based-Development doc")
    text = text.replace("{{SOURCE_ROOT}}", v.get("source_root") or "the source tree")
    return text


def render_code_review_fragment() -> str:
    return (FRAGMENTS_DIR / "code-review-checklist.md").read_text()


def render_ot_domain_fragment(v: dict) -> str:
    if v.get("domain_extension") != "ot-building-automation":
        return ""
    return (FRAGMENTS_DIR / "ot-domain-notes.md").read_text()


def render_dls_fragment(v: dict) -> str:
    if not v.get("dls_extension"):
        return ""
    return (FRAGMENTS_DIR / "dls-usage-notes.md").read_text()


MINIMAL_TEMPLATE = """# Neeve Engineering — Agent Instructions

Read by: GitHub Copilot · OpenAI Codex · Google Antigravity · Claude Code · Cursor

This file is rendered from `context-src/base.md` (minimal variant) by
`scripts/context_render.py`. Edit the source, not this file.

---

## Why This Matters

Neeve builds the security and control layer for smart buildings and critical
infrastructure. Even in a docs/scratch repo: prefer simplicity over accretion,
and name operational stakes when they're relevant.

---

## This Repo

{stack_block}

{local_dev_block}

This repo is treated as minimal-governance (docs-only, scratch, or placeholder):
no spec-review rubric, no hooks, no enforced quality gates are rendered here.
"""


def render(repo: str) -> dict[str, str]:
    v = load_repo_vars(repo)
    if v.get("minimal"):
        body = MINIMAL_TEMPLATE.format(
            stack_block=render_stack_block(v) or "_Stack not yet documented._",
            local_dev_block=render_local_dev_block(v),
        )
        return {f: body for f in OUTPUT_FILES}

    base = BASE_MD.read_text()
    rendered = (
        base.replace("{{REPO_STACK_BLOCK}}", render_stack_block(v) or "_Stack not yet documented._")
        .replace("{{REPO_LOCAL_DEV_BLOCK}}", render_local_dev_block(v))
        .replace("{{REPO_COMMANDS_BLOCK}}", render_commands_block(v))
        .replace("{{REPO_DO_NOT_MODIFY_BLOCK}}", render_do_not_modify_block(v))
        .replace("{{SPEC_REVIEW_FRAGMENT}}", render_spec_review_fragment(v))
        .replace("{{CODE_REVIEW_FRAGMENT}}", render_code_review_fragment())
        .replace("{{OT_DOMAIN_FRAGMENT}}", render_ot_domain_fragment(v))
        .replace("{{DLS_FRAGMENT}}", render_dls_fragment(v))
    )
    # Collapse runs of 3+ blank lines left behind by empty fragment substitutions.
    while "\n\n\n\n" in rendered:
        rendered = rendered.replace("\n\n\n\n", "\n\n\n")
    return {f: rendered for f in OUTPUT_FILES}


def cmd_check(repo: str, target: Path) -> int:
    outputs = render(repo)
    failed = False
    for rel_path, content in outputs.items():
        target_file = target / rel_path
        if not target_file.is_file():
            print(f"MISSING (not yet migrated, not failing): {rel_path}")
            continue
        existing = target_file.read_text()
        if existing != content:
            failed = True
            print(f"DRIFT: {rel_path}")
            diff = difflib.unified_diff(
                existing.splitlines(keepends=True),
                content.splitlines(keepends=True),
                fromfile=f"committed/{rel_path}",
                tofile=f"rendered/{rel_path}",
            )
            sys.stdout.writelines(diff)
        else:
            print(f"OK: {rel_path}")
    return 1 if failed else 0


def cmd_write(repo: str, target: Path) -> int:
    outputs = render(repo)
    for rel_path, content in outputs.items():
        target_file = target / rel_path
        target_file.parent.mkdir(parents=True, exist_ok=True)
        target_file.write_text(content)
        print(f"Wrote: {target_file}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("repo", help="Repo name, matching context-src/repos/<repo>.yaml")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", metavar="TARGET_PATH", help="Diff rendered output against TARGET_PATH")
    mode.add_argument("--write", metavar="TARGET_PATH", help="Write rendered output into TARGET_PATH")
    args = parser.parse_args()

    if args.check:
        return cmd_check(args.repo, Path(args.check).expanduser().resolve())
    return cmd_write(args.repo, Path(args.write).expanduser().resolve())


if __name__ == "__main__":
    raise SystemExit(main())
