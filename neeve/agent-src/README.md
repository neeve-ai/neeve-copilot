# Agents: cross-tool custom agents, rendered from one source

This directory holds Neeve's custom agent(s) — today, one: `neeve`, the
unified full-SDLC agent (setup/onboarding + Design Loop routing across every
skill). It previously held eight narrow agents (`to-prd`, `to-erd`,
`repo-guide`, `neeve-guide`, `neeve-reviewer`, `neeve-security-partner`,
`neeve-pm-partner`, `neeve-design-partner`); see "What changed" below for
why that was retired in favor of one agent plus the skills it routes to.
Each agent is authored once as `agent-src/<name>/AGENT.md` and rendered by
`scripts/agents_render.py` into every tool's own native format. It exists
alongside `skills-src/` (the Agent Skills: `to-prd`, `to-erd`, `repo-intel`,
`repo-ask`, `to-spec`, `implement-spec`, `code-review`, `neeve-dls`,
`ot-building-automation`, `debug-trace`) for workflows that specifically
need agent behavior — see "When to write an agent instead of a skill" below.

## What changed, and why

The previous eight-agent model had two problems this restructure fixes:

1. **Real content duplication.** `neeve-reviewer` and `neeve-security-partner`
   largely restated rubrics that already lived in the `code-review` skill's
   own reference files; `neeve-pm-partner`/`neeve-design-partner` were
   genuinely new checklists, but delivered as agents meant they were
   picker-only in GitHub Copilot (no auto-trigger) when the content itself
   didn't need agent-only capabilities.
2. **Copilot has no subagent/orchestration model** — eight agents to choose
   from in a manual picker is a worse experience than one agent that routes,
   plus skills that auto-trigger on their own regardless.

The fix: `to-prd`/`to-erd` became skills (auto-trigger in Copilot now, not
just Claude Code/Codex); `neeve-reviewer`'s and `neeve-security-partner`'s
non-duplicated content merged into `code-review/references/security.md` and
`principles.md`; `neeve-pm-partner`/`neeve-design-partner`'s checklists
became `neeve/references/pm-lens.md` and `design-review.md`, cited from
`to-spec`/`to-prd` and `neeve-dls`/`code-review` respectively; `repo-guide`
retired in favor of the rendered repo context plus `repo-ask`/`repo-intel`.
One agent, `neeve`, now routes across all of it by Design Loop stage — see
`agent-src/neeve/AGENT.md` and `neeve/engineering-principles.md`.

## Why a render step, not one shared file

Three tools have a real, working, global custom-agent mechanism today —
each in an incompatible format, confirmed directly against each tool's 2026
documentation, not assumed:

| Tool | Global mechanism | Format | Auto-triggers on phrasing? |
|---|---|---|---|
| Claude Code | `~/.claude/agents/*.md` | Markdown + YAML frontmatter | Yes — matches `description` against the request, same as Skills |
| GitHub Copilot (VS Code) | user-profile agents folder | `.agent.md`, same family, plus `target`/`user-invocable` | Picker-first; can opt into model-invocation, but the default is explicit selection |
| Codex CLI | `~/.codex/agents/*.toml` | **TOML**, not Markdown | No — explicit only, via `/agent` |
| Cursor | none — "Custom Modes" was deprecated in 2026, no replacement | — | — |
| Antigravity | none confirmed — orchestrator invents its own ephemeral subagents at runtime, no user-authored persistent mechanism | — | — |

Cursor and Antigravity get a **Skill-shaped fallback** rendered from the
same `AGENT.md` source instead of a hand-authored second file. Notably, the
skill fallback auto-triggers on phrasing, which is *more* automatic than
Codex's explicit-only custom agents — this is a real invocation-consistency
difference across tools, not a rounding error.

## Source format

```
agent-src/
  neeve/
    AGENT.md
```

Each `AGENT.md` is one file: a small, restricted frontmatter (`name:`,
`description: >` as a folded scalar, `tools:` as a list) followed by the
full agent body. `scripts/agents_render.py <name>
--claude|--copilot|--codex|--skill-fallback` renders each target;
`install.sh` calls all four per detected tool, and prunes the eight retired
agent files/dirs first so a stale install doesn't leave ghost agents behind.
The body is never forked — every rendered form carries the identical
markdown content, only the frontmatter wrapper differs per tool.

## When to write a new agent instead of a skill

Skills remain the default — cross-tool portable everywhere, load
automatically, no per-tool format translation needed, and bundled behind
`neeve`'s own routing rather than needing separate discovery. Write a new
`agent-src/<name>/AGENT.md` only when the workflow needs something a skill
can't express as cleanly, and think hard before doing it — the eight-agent
history above is exactly what happens when that bar isn't held:

- **Isolated tool access or subagent delegation** — the workflow should run
  with a restricted tool set, or needs to spawn/coordinate its own
  subagents, not just follow a linear instruction set. (Note: Copilot has no
  subagent model at all, so this reasoning doesn't carry over there.)
- **A genuinely distinct identity that must exist independent of `neeve`'s
  own routing** — not "a checklist" (that's a skill or a reference file
  cited by one), a persona with its own tool-access boundary.

If in doubt, it's a skill or a reference file cited from `neeve`'s routing
table — that's the right default for nearly everything.
