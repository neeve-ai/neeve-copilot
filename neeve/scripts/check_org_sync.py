#!/usr/bin/env python3
"""Assertion-based consistency check for Neeve's unified `neeve` agent and
its canonical reference files.

Historically this checked eight narrow specialist agents' citations against
`PRINCIPLES.md`/`security.md`. That structure is retired: `to-prd`/`to-erd`
are now skills, `repo-guide`/`neeve-reviewer`/`neeve-security-partner`/
`neeve-pm-partner`/`neeve-design-partner` are folded into existing skills and
two new reference files, and a single `neeve` agent routes to all of them.
This check now asserts three things instead:

1. `agent/neeve/AGENT.md`'s routing table names every skill that ships
   under either skills root exactly once — a new skill added without a
   routing-table entry fails this, catching silent drift between what's
   installed and what the agent tells engineers to use.
2. `code-review/references/security.md` still has the section headings the
   `neeve` agent's Escalation Rules and `neeve/references/*.md` cite.
3. The new `neeve/references/pm-lens.md` and `design-review.md` still cite
   `foundation.md`/`engineering-principles.md`, so a rename/removal there
   doesn't leave a stale reference.

Usage: python3 neeve/scripts/check_org_sync.py
Exit 0 if all checks pass, 1 otherwise.
"""
from __future__ import annotations

import sys
from pathlib import Path

NEEVE_DIR = Path(__file__).resolve().parents[1]  # neeve/
AGENT_MD = NEEVE_DIR / "agent" / "neeve" / "AGENT.md"
SECURITY_MD = NEEVE_DIR / "skills" / "code-review" / "references" / "security.md"
FOUNDATION_MD = NEEVE_DIR / "foundation.md"
ENGINEERING_PRINCIPLES_MD = NEEVE_DIR / "engineering-principles.md"
PM_LENS_MD = NEEVE_DIR / "references" / "pm-lens.md"
DESIGN_REVIEW_MD = NEEVE_DIR / "references" / "design-review.md"

PRODUCTS_DIR = NEEVE_DIR / "products"
SKILLS_SRC_ROOTS = [NEEVE_DIR / "skills"] + (
    [p / "skills" for p in sorted(PRODUCTS_DIR.iterdir()) if p.is_dir()]
    if PRODUCTS_DIR.is_dir()
    else []
)

# Section headings that must still exist in the source docs — catches a
# rename/removal even before checking what cites them.
REQUIRED_SOURCE_HEADINGS: dict[Path, list[str]] = {
    SECURITY_MD: [
        "OWASP Top 10",
        "Pentest Mindset",
        "Security Gates",
        "Enterprise SaaS Multi-Tenancy",
        "Escalation",
    ],
}

# Each of these files must still cite the given substrings — catches a
# reference file going stale against the docs it's derived from.
REQUIRED_CITATIONS: dict[Path, list[str]] = {
    PM_LENS_MD: ["foundation.md", "engineering-principles.md"],
    DESIGN_REVIEW_MD: ["engineering-principles.md"],
}


def discover_skill_names() -> list[str]:
    names: list[str] = []
    for root in SKILLS_SRC_ROOTS:
        if not root.is_dir():
            continue
        for p in sorted(root.iterdir()):
            if p.is_dir() and (p / "SKILL.md").is_file():
                names.append(p.name)
    return names


def check_agent_routes_every_skill() -> list[str]:
    errors: list[str] = []
    if not AGENT_MD.is_file():
        return [f"missing unified agent file: {AGENT_MD}"]
    text = AGENT_MD.read_text()
    for name in discover_skill_names():
        # A skill is "named" if its bare name appears literally in backticks,
        # matching how the routing table and prose reference skills.
        if f"`{name}`" not in text:
            errors.append(
                f"{AGENT_MD.name}: skill {name!r} ships under skills but "
                f"is not named in the routing table — add a row or an "
                f"explicit reference."
            )
    return errors


def check_source_headings() -> list[str]:
    errors = []
    for path, headings in REQUIRED_SOURCE_HEADINGS.items():
        if not path.is_file():
            errors.append(f"missing source file entirely: {path}")
            continue
        text = path.read_text()
        for heading in headings:
            if heading not in text:
                errors.append(f"{path.name}: expected heading/text {heading!r} not found")
    return errors


def check_reference_citations() -> list[str]:
    errors = []
    for path, required in REQUIRED_CITATIONS.items():
        if not path.is_file():
            errors.append(f"missing reference file: {path}")
            continue
        text = path.read_text()
        for citation in required:
            if citation not in text:
                errors.append(f"{path.name}: missing expected citation {citation!r}")
    return errors


def main() -> int:
    all_errors = (
        check_agent_routes_every_skill()
        + check_source_headings()
        + check_reference_citations()
    )
    if all_errors:
        print("consistency check FAILED:", file=sys.stderr)
        for err in all_errors:
            print(f"  - {err}", file=sys.stderr)
        return 1
    print("consistency: unified agent routes every skill, all citations present.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
