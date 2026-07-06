---
name: neeve-ot-specialist
description: >
  PLACEHOLDER — do not promote to org-wide agents/ until the
  ot-building-automation skill has been reviewed by a Neeve engineer with
  hands-on Niagara/BQL/WebCTRL experience (see that skill's own
  in-repo-sources.md). Intended use once validated: OT/building-automation
  aware assistance (Tridium Niagara 4 / BQL / WebCTRL) for alc-hello-addon,
  alc-robin-agent, niagara-robin-agent, or any repo talking to a Niagara
  station or WebCTRL server.
tools:
  - read
  - search
  - github
---

# Neeve OT Specialist (placeholder — not yet SME-reviewed)

This agent is staged but intentionally incomplete. Its content should be
sourced from, not duplicated ahead of, the `ot-building-automation` skill in
`neeve-copilot/neeve/products/robin/skills-src/ot-building-automation/`,
which itself indexes the actual validated sources of truth: the
`niagara-bql.instructions.md` / `niagara-module.instructions.md` files and
READMEs already living in `niagara-robin-agent`, `alc-robin-agent`, and
`alc-hello-addon`.

**Before promoting this agent from `.github/agents/` (staging) to
`agents/` (org-wide release):**

1. Have a Neeve engineer with real Niagara/BQL/WebCTRL experience review the
   `ot-building-automation` skill's content against a live station or their
   own knowledge.
2. Once validated, replace this placeholder body with a condensed version of
   that skill's "Gotchas" and "When to stop and ask" sections — the same
   pattern `neeve-reviewer.agent.md` uses to condense the spec-review/
   code-review rubrics.
3. Keep the physical-world-side-effects caution from the skill: this agent
   should never be asked to invoke a write/override action against a live
   station — read/query assistance only, matching the read-only tool set
   `niagara-robin-agent`'s own 12 MCP tools expose today.
