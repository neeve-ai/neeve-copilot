# When to graduate a skill into a custom agent

This directory is intentionally empty at launch. Neeve's six workflows
(`repo-intel`, `repo-ask`, `to-spec`, `implement-spec`, `code-review`,
`neeve-dls`) are Agent Skills (`skills-src/`), not custom agents
(`.agent.md`), on purpose: skills are cross-tool portable (Claude Code,
Cursor, Codex, Copilot) and load automatically when the request matches.

Write a `.agent.md` here instead of adding another skill only when the
workflow needs something a skill can't express:

- **Isolated tool access** — the workflow should run with a restricted or
  different tool set than the calling session (e.g. read-only, or no shell).
- **Subagent delegation** — the workflow needs to spawn and coordinate
  parallel subagents, not just follow a linear set of instructions.
- **Agent-scoped hooks** — the workflow needs lifecycle hooks (PreToolUse,
  etc.) that should only fire while that specific agent is active, not for
  every session in the repo (see `hooks-src/` for the repo-wide baseline).

If none of those apply, it's a skill. Org-wide, always-available custom
agents (not tied to any one repo's skill install) live in the enterprise
`.github-private/agents/` repo instead — see `neeve/products/robin/README.md`
§ Enterprise governance.
