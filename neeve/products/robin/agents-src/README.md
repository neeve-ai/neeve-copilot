# Agents: cross-tool custom agents, rendered from one source

This directory holds Neeve's custom agents — `to-prd`, `to-erd`,
`repo-guide` — each authored once as `agents-src/<name>/AGENT.md` and
rendered by `scripts/agents_render.py` into every tool's own native format.
It exists alongside `skills-src/` (six Agent Skills: `repo-intel`,
`repo-ask`, `to-spec`, `implement-spec`, `code-review`, `neeve-dls`) for
workflows that specifically need agent behavior — see "When to write an
agent instead of a skill" below.

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
same `AGENT.md` source instead of a hand-authored second file — one of the
existing six skills' mechanisms, reused, not reinvented. Notably, the skill
fallback auto-triggers on phrasing, which is *more* automatic than Codex's
explicit-only custom agents — this is a real invocation-consistency
difference across tools, not a rounding error, and it's stated plainly in
every place this system's docs describe these agents rather than implied to
be identical everywhere.

## Source format

```
agents-src/
  to-prd/
    AGENT.md
  to-erd/
    AGENT.md
  repo-guide/
    AGENT.md
```

Each `AGENT.md` is one file: a small, restricted frontmatter (`name:`,
`description: >` as a folded scalar, `tools:` as a list) followed by the
full agent body (Producer Contract, Workflow, Output template, Skill/Agent
Chain — the same shape `to-spec`/`neeve-dls` already use). `scripts/
agents_render.py <name> --claude|--copilot|--codex|--skill-fallback` renders
each target; `install.sh` calls all four per detected tool. The body is
never forked — every rendered form carries the identical markdown content,
only the frontmatter wrapper differs per tool.

## When to write an agent instead of a skill

Skills remain the default — cross-tool portable everywhere, load
automatically, no per-tool format translation needed. Write a new
`agents-src/<name>/AGENT.md` instead only when the workflow needs something
a skill can't express as cleanly:

- **A specialist "brought in for one job"**, invoked the way a person is —
  by name, natively — rather than a how-to manual loaded mid-task. `to-prd`
  and `to-erd` are this: an engineer or PM asks for a PRD or a work-item
  breakdown directly, the way they'd ask a specific colleague, not "consult
  the PRD-writing skill."
- **Repo-aware, not task-aware** — `repo-guide` answers "what shouldn't I
  touch here" for whichever repo you're sitting in; that's an identity
  (a guide who knows this repo), not a linear workflow a skill's phases fit.
- **Isolated tool access or subagent delegation** — the workflow should run
  with a restricted tool set, or needs to spawn/coordinate its own
  subagents, not just follow a linear instruction set.

If none of those apply, it's a skill — that's still the right default for
most new workflows.

## Relationship to `neeve/org/`

`neeve/org/`'s 5 agents (`neeve-reviewer`, `neeve-security-partner`,
`neeve-pm-partner`, `neeve-design-partner`, `neeve-ot-specialist`) are a
separate, older mechanism: GitHub-Enterprise-only, exported to a
`neeve-ai/.github-private` repo, reaching Copilot on github.com exclusively
— and only once that (not-yet-started) Enterprise setup is live. They do not
reach Claude Code, Cursor, Codex, or Antigravity at all today. This
directory's render mechanism could plausibly replace that export path for
those five too, since it actually reaches every tool globally — noted as a
future option in `neeve/org/README.md`, not undertaken here.
