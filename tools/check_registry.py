#!/usr/bin/env python3
"""Validate registry/repos.yaml and registry/sources.yaml.

Deterministic, model-free (A-2). Two checks:

  (default)     A-1 — no domain in sources.yaml names two different
                system-of-record values.
  --coverage    Every knowledge layer in docs/redesign/ARCHITECTURE.md §3
                has at least one entry in sources.yaml.
"""
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
REPOS_PATH = ROOT / "registry" / "repos.yaml"
SOURCES_PATH = ROOT / "registry" / "sources.yaml"
ARCHITECTURE_PATH = ROOT / "docs" / "redesign" / "ARCHITECTURE.md"


def load_yaml(path: Path) -> dict:
    with path.open() as f:
        return yaml.safe_load(f) or {}


def check_repos_present() -> list[str]:
    """Basic shape check: every repo has purpose, owner, products."""
    errors = []
    data = load_yaml(REPOS_PATH)
    repos = data.get("repos") or []
    if not repos:
        errors.append(f"{REPOS_PATH}: no repos defined")
    seen_ids = set()
    for repo in repos:
        repo_id = repo.get("id")
        if not repo_id:
            errors.append(f"{REPOS_PATH}: repo entry missing 'id': {repo!r}")
            continue
        if repo_id in seen_ids:
            errors.append(f"{REPOS_PATH}: duplicate repo id '{repo_id}'")
        seen_ids.add(repo_id)
        for field in ("purpose", "owner", "products"):
            if not repo.get(field):
                errors.append(f"{REPOS_PATH}: repo '{repo_id}' missing '{field}'")
    return errors


def check_a1_one_sor_per_domain() -> list[str]:
    """A-1: reject any domain with two sor values."""
    errors = []
    data = load_yaml(SOURCES_PATH)
    domains = data.get("domains") or []
    sor_by_domain: dict[str, set[str]] = {}
    for entry in domains:
        name = entry.get("domain")
        sor = entry.get("sor")
        if not name:
            errors.append(f"{SOURCES_PATH}: domain entry missing 'domain': {entry!r}")
            continue
        if sor is None:
            errors.append(f"{SOURCES_PATH}: domain '{name}' missing 'sor'")
            continue
        sor_by_domain.setdefault(name, set()).add(sor)
    for name, sors in sor_by_domain.items():
        if len(sors) > 1:
            errors.append(
                f"{SOURCES_PATH}: domain '{name}' has {len(sors)} system-of-record "
                f"values (A-1 violation): {sorted(sors)}"
            )
    return errors


def architecture_layers() -> list[str]:
    """Extract the unique layer codes from ARCHITECTURE.md §3's table."""
    text = ARCHITECTURE_PATH.read_text()
    match = re.search(
        r"## 3\. Knowledge layers.*?\n(.*?)\n---", text, re.DOTALL
    )
    if not match:
        raise RuntimeError(f"could not find §3 table in {ARCHITECTURE_PATH}")
    section = match.group(1)
    layers = []
    seen = set()
    for line in section.splitlines():
        cell_match = re.match(r"\|\s*\*{0,2}([0-9½]+[a-z]?)\*{0,2}\s*\|", line)
        if not cell_match:
            continue
        code = cell_match.group(1)
        if code not in seen:
            seen.add(code)
            layers.append(code)
    return layers


def check_coverage() -> list[str]:
    """Every ARCHITECTURE.md §3 layer has a sources.yaml entry."""
    errors = []
    required = architecture_layers()
    data = load_yaml(SOURCES_PATH)
    domains = data.get("domains") or []
    covered = {entry.get("layer") for entry in domains if entry.get("layer")}
    missing = [layer for layer in required if layer not in covered]
    if missing:
        errors.append(
            f"{SOURCES_PATH}: missing an entry for ARCHITECTURE.md §3 layer(s): {missing}"
        )
    return errors


def main() -> int:
    coverage_mode = "--coverage" in sys.argv[1:]

    errors = check_repos_present()
    errors += check_a1_one_sor_per_domain()
    if coverage_mode:
        errors += check_coverage()

    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        return 1

    if coverage_mode:
        print("OK: every ARCHITECTURE.md §3 layer has a sources.yaml entry")
    else:
        print("OK: registry/repos.yaml and registry/sources.yaml are valid (A-1 holds)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
