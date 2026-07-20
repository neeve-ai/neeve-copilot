#!/usr/bin/env python3
"""Render the global house-rules content installed by neeve-copilot.

Repo-specific context now lives in each repo's committed OKF book
(`introduction.md`, `index.md`, `appendix.md`), so this renderer only keeps
the universal house-rules variant current.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # neeve/
# Org-level (product-agnostic) context: base.md + tier-1 fragments.
CONTEXT_SRC = ROOT / "context"
BASE_MD = CONTEXT_SRC / "base.md"
# Product-level context: product overview plus product-specific fragments.
PRODUCT_CONTEXT_SRC = ROOT / "products" / "robin" / "context"


def _fragment_path(name: str) -> Path:
    """Resolve a fragment by name: org fragments first, then product."""
    org = CONTEXT_SRC / "fragments" / name
    if org.is_file():
        return org
    return PRODUCT_CONTEXT_SRC / "fragments" / name

OUTPUT_FILES = ["AGENTS.md", ".github/copilot-instructions.md", "CLAUDE.md", ".cursorrules"]


def render_spec_review_fragment() -> str:
    return _fragment_path("spec-review-checklist.md").read_text()


def render_code_review_fragment() -> str:
    return _fragment_path("code-review-checklist.md").read_text()


def render_production_consequence_fragment() -> str:
    return _fragment_path("production-consequence-and-gaps.md").read_text()


def render_product_overview_fragment() -> str:
    return (PRODUCT_CONTEXT_SRC / "product-overview.md").read_text()


def render_ot_domain_fragment() -> str:
    return _fragment_path("ot-domain-notes.md").read_text()


def render_dls_fragment() -> str:
    return _fragment_path("dls-usage-notes.md").read_text()


HOUSE_RULES_HEADER = """# Neeve Engineering — House Rules

Read by: GitHub Copilot · OpenAI Codex · Claude Code (global instructions,
every workspace on this machine).

This file is rendered from `context/base.md` (house-rules variant, the
universal parts only — no repo-specific stack/commands/do-not-modify) by
`scripts/context_render.py --house-rules`. It is installed once per engineer
via `install.sh`/`sync_skills.sh` into each tool's user-level instructions
location, not committed into any product repo. Edit `context/base.md`,
then re-run the installer to refresh it on your machine."""

REPO_SPECIFIC_FRAGMENT_POINTER = """If this repo does spec-based development, touches the `dls-neeve` design
system, or talks to Niagara/WebCTRL building-automation systems, the
relevant skill (`to-spec`, `neeve-dls`, or `ot-building-automation`) carries
the full rubric/notes for that and triggers on its own — it isn't
duplicated here since it doesn't apply to every repo."""


def render_house_rules() -> str:
    """Universal-only variant of base.md: house rules with no repo-specific
    facts and no repo-conditional fragments (those live in the skills that
    already trigger on their own, not duplicated here) — installed once,
    user-level, via install.sh, not committed into any product repo."""
    base = BASE_MD.read_text()

    # Drop the per-repo-render header/comment, replace with a house-rules one.
    _, _, rest = base.partition("---\n\n## Why This Matters")
    body = "## Why This Matters" + rest

    rendered = (
        body.replace("{{PRODUCT_OVERVIEW_FRAGMENT}}", render_product_overview_fragment())
        .replace("{{PRODUCTION_CONSEQUENCE_FRAGMENT}}", render_production_consequence_fragment())
        .replace("{{REPO_COMMANDS_BLOCK}}", "")
        .replace("{{REPO_DO_NOT_MODIFY_BLOCK}}", "")
        .replace("{{SPEC_REVIEW_FRAGMENT}}", "")
        .replace("{{CODE_REVIEW_FRAGMENT}}", "")
        .replace("{{OT_DOMAIN_FRAGMENT}}", "")
        .replace("{{DLS_FRAGMENT}}", REPO_SPECIFIC_FRAGMENT_POINTER)
    )
    while "\n\n\n\n" in rendered:
        rendered = rendered.replace("\n\n\n\n", "\n\n\n")
    return HOUSE_RULES_HEADER + "\n\n---\n\n" + rendered.strip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--house-rules",
        required=True,
        metavar="OUTPUT_FILE",
        help="Write the universal-only house-rules variant to OUTPUT_FILE",
    )
    args = parser.parse_args()

    out = Path(args.house_rules).expanduser().resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(render_house_rules())
    print(f"Wrote: {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
