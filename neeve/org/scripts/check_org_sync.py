#!/usr/bin/env python3
"""Assertion-based consistency check for Neeve's specialist agents.

Unlike context_render.py's byte-for-byte diff, these agent files are
deliberately condensed prose, not a mechanical render of base.md/security.md/
PRINCIPLES.md — so this check can't diff them against a generated "expected"
output. Instead it asserts each agent still textually cites the specific
sections it claims to apply, catching the case where base.md/security.md/
PRINCIPLES.md is restructured (a heading renamed or removed) and an agent's
citation silently goes stale.

Four agents (`neeve-reviewer`, `neeve-security-partner`, `neeve-pm-partner`,
`neeve-design-partner`) were migrated to `agents-src/<name>/AGENT.md` so they
reach every engineer/tool via the same render pipeline as `to-prd`/`to-erd`/
`repo-guide`, retiring the GitHub-Enterprise-only `.github-private` export
path for them. `neeve-ot-specialist` stays in `neeve/org/.github/agents/` —
it's gated on SME content review, not distribution; migrate it the same way
once it's validated.

Usage: python3 neeve/org/scripts/check_org_sync.py
Exit 0 if every agent's required citations are present, 1 otherwise.
"""
from __future__ import annotations

import sys
from pathlib import Path

ORG_DIR = Path(__file__).resolve().parents[1]
AGENTS_DIR = ORG_DIR / ".github" / "agents"
NEEVE_DIR = ORG_DIR.parent
AGENTS_SRC_DIR = NEEVE_DIR / "products" / "robin" / "agents-src"
SECURITY_MD = NEEVE_DIR / "products" / "robin" / "skills-src" / "code-review" / "references" / "security.md"
PRINCIPLES_MD = ORG_DIR / "PRINCIPLES.md"
BASE_MD = NEEVE_DIR / "products" / "robin" / "context-src" / "base.md"

# Per-agent: substrings that MUST appear in the agent's own file, and where
# that file now lives. These are citations, not full duplication — the agent
# should point at the section, not restate it. Keep loose (a distinctive
# phrase from the heading) so a reasonable heading rewording doesn't
# spuriously fail this, but a real section removal/rename does.
REQUIRED_CITATIONS: dict[Path, list[str]] = {
    AGENTS_SRC_DIR / "neeve-security-partner" / "AGENT.md": [
        "OWASP",
        "Pentest Mindset",
        "Security Gates",
        "Multi-Tenancy",
    ],
    AGENTS_SRC_DIR / "neeve-pm-partner" / "AGENT.md": [
        "PRINCIPLES.md",
        "Product Management",
    ],
    AGENTS_SRC_DIR / "neeve-design-partner" / "AGENT.md": [
        "PRINCIPLES.md",
        "Design",
    ],
    AGENTS_SRC_DIR / "neeve-reviewer" / "AGENT.md": [
        "PRINCIPLES.md",
        "Engineering",
    ],
}

# Section headings that must still exist in the source docs (independent of
# any one agent) — catches a rename/removal even before checking citations.
REQUIRED_SOURCE_HEADINGS: dict[Path, list[str]] = {
    SECURITY_MD: [
        "OWASP Top 10",
        "Pentest Mindset",
        "Security Gates",
        "Enterprise SaaS Multi-Tenancy",
    ],
    PRINCIPLES_MD: [
        "## Product Management",
        "## Design",
        "## Engineering",
    ],
}

PLACEHOLDER_AGENTS = {"neeve-ot-specialist.agent.md"}


def check_source_headings() -> list[str]:
    errors = []
    for path, headings in REQUIRED_SOURCE_HEADINGS.items():
        if not path.is_file():
            errors.append(f"missing source file entirely: {path}")
            continue
        text = path.read_text()
        for heading in headings:
            if heading not in text:
                errors.append(f"{path.name}: expected heading/text {heading!r} not found — an agent likely cites this")
    return errors


def check_agent_citations() -> list[str]:
    errors = []
    for agent_path, required in REQUIRED_CITATIONS.items():
        if not agent_path.is_file():
            errors.append(f"missing agent file: {agent_path}")
            continue
        text = agent_path.read_text()
        for citation in required:
            if citation not in text:
                errors.append(f"{agent_path.name}: missing expected citation {citation!r}")
    return errors


def check_placeholders_still_flagged() -> list[str]:
    errors = []
    for filename in PLACEHOLDER_AGENTS:
        agent_path = AGENTS_DIR / filename
        if not agent_path.is_file():
            errors.append(f"missing placeholder agent file: {filename}")
            continue
        text = agent_path.read_text()
        if "PLACEHOLDER" not in text:
            errors.append(
                f"{filename}: no longer marked PLACEHOLDER — if it was promoted, "
                f"remove it from PLACEHOLDER_AGENTS in this script and add it to "
                f"REQUIRED_CITATIONS instead."
            )
    return errors


def main() -> int:
    all_errors = (
        check_source_headings()
        + check_agent_citations()
        + check_placeholders_still_flagged()
    )
    if all_errors:
        print("neeve/org sync check FAILED:", file=sys.stderr)
        for err in all_errors:
            print(f"  - {err}", file=sys.stderr)
        return 1
    print("neeve/org: all agent citations present, all placeholders still flagged.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
