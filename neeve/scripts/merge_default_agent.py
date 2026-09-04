#!/usr/bin/env python3
"""Idempotently set the `agent` key in a Claude Code settings.json — mirrors
merge_session_hook.py's idempotency discipline for the same reason: only the
one key we own is touched, every other key already in the file (permissions,
hooks, MCP servers, personal overrides) is preserved untouched.

Deliberately generic over which settings.json (global, project, or local) —
the caller decides scope; this script never guesses it. Two call sites use
it with different force semantics:

- init-repo.sh, per repo, force mode (the default): `.claude/settings.local.json`
  is this project's OWN dedicated file for this one purpose, and re-running
  init-repo.sh is an explicit, deliberate per-repo action each time — so it
  always sets `agent` to the current value, the same way the OKF book's
  other per-repo steps are safe to re-run and converge to the current state.
- install.sh, globally, `--only-if-unset` mode: `~/.claude/settings.json` is
  a general-purpose file an engineer may have already customized — including
  possibly to something other than neeve, or deliberately to nothing. A
  routine `sync_skills.sh` run must never silently override a decision an
  engineer already made, any more than merge_house_rules.py overrides
  content outside its markers. `--only-if-unset` sets the default exactly
  once, the first time the key doesn't exist yet, and never touches it again
  after that — the same "developer-local overrides win" principle
  `agent/neeve/AGENT.md`'s own "Respecting Developer-Local Overrides"
  section already states for every other layer.

Usage: merge_default_agent.py <settings.json path> <agent-name> [--only-if-unset]
       merge_default_agent.py <settings.json path> <agent-name> --upgrade-from <old-value>
"""
from __future__ import annotations

import json
import sys
from pathlib import Path


def merge(
    settings_path: Path,
    agent_name: str,
    only_if_unset: bool = False,
    upgrade_from: str | None = None,
) -> bool:
    """Returns True if the file changed, False if left as-is.

    only_if_unset=False, upgrade_from=None (default): force-set `agent` to
    agent_name, the same way every other key this system manages converges
    to the current source of truth on each run.

    only_if_unset=True: set `agent` only if the key is completely absent from
    the file. If it's already present — to agent_name, to something else, or
    to an explicit empty/null the engineer set to opt out — leave it exactly
    as-is. This is a one-time default, not an enforced value.

    upgrade_from=<old value>: rewrite `agent` to agent_name only when the
    current value equals exactly upgrade_from. This is the forward-migration
    path `--only-if-unset` cannot provide — it corrects a known-stale value
    without touching a file where the key is unset, already current, or
    deliberately set to something else (including an explicit null opt-out,
    which never equals a non-null upgrade_from).
    """
    if settings_path.is_file() and settings_path.stat().st_size > 0:
        data = json.loads(settings_path.read_text())
    else:
        data = {}

    if upgrade_from is not None:
        if data.get("agent") != upgrade_from:
            return False
    elif only_if_unset:
        if "agent" in data:
            return False
    elif data.get("agent") == agent_name:
        return False

    data["agent"] = agent_name
    settings_path.parent.mkdir(parents=True, exist_ok=True)
    settings_path.write_text(json.dumps(data, indent=2) + "\n")
    return True


def main() -> int:
    only_if_unset = "--only-if-unset" in sys.argv[1:]
    upgrade_from: str | None = None
    args = []
    i = 1
    while i < len(sys.argv):
        arg = sys.argv[i]
        if arg == "--only-if-unset":
            i += 1
            continue
        if arg == "--upgrade-from":
            if i + 1 >= len(sys.argv):
                print("Usage: merge_default_agent.py <settings.json path> <agent-name> --upgrade-from <old-value>", file=sys.stderr)
                return 1
            upgrade_from = sys.argv[i + 1]
            i += 2
            continue
        args.append(arg)
        i += 1

    if len(args) != 2:
        print(
            "Usage: merge_default_agent.py <settings.json path> <agent-name> [--only-if-unset]\n"
            "       merge_default_agent.py <settings.json path> <agent-name> --upgrade-from <old-value>",
            file=sys.stderr,
        )
        return 1
    if only_if_unset and upgrade_from is not None:
        print("--only-if-unset and --upgrade-from are mutually exclusive", file=sys.stderr)
        return 1

    settings_path = Path(args[0]).expanduser().resolve()
    agent_name = args[1]
    changed = merge(settings_path, agent_name, only_if_unset=only_if_unset, upgrade_from=upgrade_from)
    mode = "upgrade-from" if upgrade_from is not None else ("only-if-unset" if only_if_unset else "force")
    print(f"{'Wrote' if changed else 'Already set (left as-is)'}: {settings_path} (agent={agent_name}, mode={mode})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
