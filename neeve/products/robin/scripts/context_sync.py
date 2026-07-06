#!/usr/bin/env python3
"""Sync-on-merge: render+sync everything a repo should have from neeve-copilot's
current source, into a target checkout, and report what changed.

This is the mechanism that replaces a one-time manual bulk push: it's meant
to run inside a CI job (triggered by a merge to the target repo's main),
compare fresh output against what's currently committed there, write only
what's actually different, and let the calling workflow commit/push/open a
review PR — this script never touches git itself.

Usage:
    context_sync.py <repo> <target-path>

Exit 0 always (whether or not anything changed) — the calling workflow reads
stdout to decide what to do:
    NO_CHANGE
or:
    CHANGED
    <newline-separated list of relative paths written or that would need to
    change, for the PR body>
"""
from __future__ import annotations

import sys
from pathlib import Path

import context_render as cr

ROOT = cr.ROOT  # neeve/products/robin
PROMPTS_SRC = ROOT / "prompts-src"
HOOKS_SRC = ROOT / "hooks-src"
SKILLS_SRC = ROOT / "skills-src"

# Skills that get installed project-scoped into specific repos (not the
# always-on-context instructions layer) — mirrors install.sh's own project
# skill logic for the one skill that's repo-specific today.
PROJECT_SKILLS_BY_DOMAIN = {"ot-building-automation": "ot-building-automation"}


def sync_instructions(v: dict, target: Path) -> list[str]:
    changed = []
    outputs = cr.render(v["repo"])
    for rel_path, content in outputs.items():
        target_file = target / rel_path
        existing = target_file.read_text() if target_file.is_file() else None
        if existing != content:
            target_file.parent.mkdir(parents=True, exist_ok=True)
            target_file.write_text(content)
            changed.append(rel_path)
    return changed


def sync_prompts(target: Path) -> list[str]:
    changed = []
    prompt_files = sorted(PROMPTS_SRC.glob("*.prompt.md"))
    if not prompt_files:
        return changed
    dest_dir = target / ".github" / "prompts"
    for src_file in prompt_files:
        dest_file = dest_dir / src_file.name
        existing = dest_file.read_text() if dest_file.is_file() else None
        content = src_file.read_text()
        if existing != content:
            dest_dir.mkdir(parents=True, exist_ok=True)
            dest_file.write_text(content)
            changed.append(str(dest_file.relative_to(target)))
    return changed


def sync_hooks(v: dict, target: Path) -> list[str]:
    """Only for repos with spec_based_development: true."""
    changed = []
    if not v.get("spec_based_development"):
        return changed
    dest_dir = target / ".github" / "hooks"

    hooks_json_src = HOOKS_SRC / "baseline.hooks.json"
    hooks_json_dest = dest_dir / "hooks.json"
    existing = hooks_json_dest.read_text() if hooks_json_dest.is_file() else None
    content = hooks_json_src.read_text()
    if existing != content:
        dest_dir.mkdir(parents=True, exist_ok=True)
        hooks_json_dest.write_text(content)
        changed.append(str(hooks_json_dest.relative_to(target)))

    for script_src in sorted((HOOKS_SRC / "scripts").glob("*.sh")):
        script_dest = dest_dir / "scripts" / script_src.name
        existing = script_dest.read_text() if script_dest.is_file() else None
        content = script_src.read_text()
        if existing != content:
            script_dest.parent.mkdir(parents=True, exist_ok=True)
            script_dest.write_text(content)
            script_dest.chmod(0o755)
            changed.append(str(script_dest.relative_to(target)))
    return changed


def sync_project_skill(v: dict, target: Path) -> list[str]:
    """Only for repos whose yaml sets domain_extension to a project-scoped skill."""
    changed = []
    domain = v.get("domain_extension")
    skill_name = PROJECT_SKILLS_BY_DOMAIN.get(domain)
    if not skill_name:
        return changed

    src_dir = SKILLS_SRC / skill_name
    dest_dir = target / ".github" / "skills" / skill_name
    for src_file in sorted(src_dir.rglob("*")):
        if src_file.is_dir():
            continue
        rel = src_file.relative_to(src_dir)
        dest_file = dest_dir / rel
        existing = dest_file.read_text() if dest_file.is_file() else None
        content = src_file.read_text()
        if existing != content:
            dest_file.parent.mkdir(parents=True, exist_ok=True)
            dest_file.write_text(content)
            changed.append(str(dest_file.relative_to(target)))
    return changed


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: context_sync.py <repo> <target-path>", file=sys.stderr)
        return 2

    repo, target_arg = sys.argv[1], sys.argv[2]
    target = Path(target_arg).expanduser().resolve()
    v = cr.load_repo_vars(repo)
    v["repo"] = v.get("repo") or repo

    all_changed: list[str] = []
    all_changed += sync_instructions(v, target)
    all_changed += sync_prompts(target)
    all_changed += sync_hooks(v, target)
    all_changed += sync_project_skill(v, target)

    if not all_changed:
        print("NO_CHANGE")
        return 0

    print("CHANGED")
    for path in all_changed:
        print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
