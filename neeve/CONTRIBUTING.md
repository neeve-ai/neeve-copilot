# Contributing to neeve-copilot

This is the one place that answers "where does this go" and "how do I know
it's right" for anyone adding or changing content in this repo — a new
skill, a new checklist, a wording change to house rules, a new product. It
exists so every addition gets placed by the same logic and checked the same
way, regardless of who's adding it or which AI tool they're using to do it.

Read this before adding content, not after something drifts.

---

## 1. Place it by layer, not by convenience

Every file in this repo is part of one of the 4 Layers of Context (full
model: `neeve/README.md`). Before adding anything, name which layer it's
for — that answers "where does this go" almost by itself:

| Layer | What it is | Lives in this repo? | Add/edit here |
|---|---|---|---|
| 04. Neeve Foundation | Company identity, culture, product, customer personas | Yes | `neeve/foundation.md` |
| 03. Engineering Principles | SDLC process principles, quality gates, security posture | Yes | `neeve/engineering-principles.md`, `neeve/references/*.md` |
| 02. Repository-Level Context | The OKF book (`introduction.md`/`index.md`/`appendix.md`) | **No** — committed into each *product* repo by `init-repo.sh` + `repo-intel`, never here | N/A from this repo |
| 01. Custom & User Context | Developer-local overrides, personal instructions | **Mostly no** — the content lives outside any `BEGIN/END NEEVE` marker in the engineer's own dotfiles | Only the *precedence rule* for when it conflicts with a house rule lives here, in `neeve/agent/neeve/AGENT.md`'s "Respecting Developer-Local Overrides" section — edit there if that rule needs to change |

If what you're adding is genuinely repo-specific knowledge about *a product
repo* (e.g. "how robin-ai's auth works"), it does not belong in
neeve-copilot at all — it belongs in that repo's own `.help/` OKF book. This
repo only ever ships Layers 03 and 04, plus the skills/agent/hooks that
*produce* Layer 02 in a target repo.

---

## 2. Decision tree: what am I adding?

| You're adding... | It goes in... | Because |
|---|---|---|
| A cross-cutting SDLC principle (applies to every stage/skill) | `neeve/engineering-principles.md` | Layer 03, cited by skills — never restated inside a skill |
| A company-identity/persona fact | `neeve/foundation.md` | Layer 04 |
| A whole new multi-step capability (its own workflow, own trigger phrases) | A new skill under `neeve/skills/<name>/` (or `neeve/products/<product>/skills/<name>/` if product-specific) | See §3 — this is the highest-bar addition, not the default |
| A deeper checklist/rubric used by exactly one skill | A `references/*.md` file inside that skill's own directory | Keeps the `SKILL.md` body short; only that skill loads it |
| A checklist/fragment shared by more than one skill (e.g. quality gates, security) | `neeve/references/*.md`, synced into each consuming skill by `shared_refs_sync.sh` | One canonical source, never hand-duplicated — see §4 |
| A house-rules-level fragment gated by product or domain (e.g. OT notes, DLS notes) | `neeve/context/fragments/` (org) or `neeve/products/<product>/context/fragments/` (product-specific) | Rendered into house rules by `context_render.py`; only included where relevant |
| A new product line (not just a new repo under Robin) | `neeve/products/<new-product>/` following Robin's existing shape (`context/`, `skills/`) | Mirrors the one working example rather than inventing a new shape |
| A new custom agent (not a skill) | `neeve/agent/<name>/AGENT.md` — **read `neeve/agent/README.md`'s bar first** | Deliberately the rarest addition; a skill is almost always the right call instead |

**Default to a skill's `references/` file over a new skill, and a new skill
over a new agent.** Each step up that ladder is a bigger surface to keep in
sync across five tools — see `neeve/agent/README.md`'s "What changed, and
why" for what an 8-agent model cost before this repo collapsed it to one.

---

## 3. Adding a new skill

A new skill is justified when the work is a genuinely distinct capability
with its own trigger phrases and its own multi-step workflow — not when
it's a checklist that could hang off an existing skill.

1. **Pick the root.** Product-agnostic (applies to any Neeve repo) →
   `neeve/skills/<name>/`. Specific to one product's stack (like `neeve-dls`
   or `ot-building-automation` are to Robin) → `neeve/products/<product>/skills/<name>/`.
2. **Write `SKILL.md`** with the standard frontmatter (`name`,
   `description: >` with concrete trigger phrases, no `tools:` field —
   that's agent-only). Model the body on an existing skill of similar shape
   (`to-spec` for a multi-phase workflow, `repo-ask` for a short focused one).
3. **Route it.** Add the skill to `neeve/agent/neeve/AGENT.md`'s Design
   Loop routing table — this is not optional, `check_org_sync.py` fails the
   build if a shipped skill isn't named there.
4. **Cite shared references, never duplicate them.** If the skill needs
   quality gates, security, or another canonical doc, add it to
   `shared_refs_sync.sh`'s destination list rather than pasting the content
   in — see §4.
5. **Verify** (§5) before opening a PR.

---

## 4. Adding or editing "instructions" (house rules, skill content, fragments)

- **Editing `neeve/context/base.md`** (the house-rules source): this
  installs into every engineer's global instructions on every tool, on
  their next `sync_skills.sh` run. Treat a wording change here as
  high-blast-radius — it's read on every request, in every repo, by every
  engineer. Run `python3 neeve/scripts/context_render.py --house-rules /tmp/out.md`
  and read the rendered output before committing, not just the source diff.
- **Editing a canonical shared reference** (`neeve/references/quality-gates.md`,
  `code-review/references/security.md`, etc.): edit the canonical file only.
  Never hand-edit a `<!-- GENERATED -->`-headered copy — `shared_refs_sync.sh sync`
  regenerates those, and `check` (run in CI) fails if a generated copy has
  drifted from its source.
- **Editing a skill's own `SKILL.md` or `references/`**: no cross-skill sync
  concern, but re-run that skill's own logic checks if it has any (e.g.
  `repo-intel`'s freshness contract, `to-spec`'s rubric numbering — don't
  renumber a canonical checklist without checking what cites it by number).

---

## 5. Objective verification — the same gate CI runs

Every addition, regardless of type, is checked by these commands before it
can merge (`.github/workflows/ci.yml` runs all of them; run them locally
first so you're not waiting on CI to find out):

```bash
# Shared reference docs are in sync (no generated copy hand-edited/stale)
bash neeve/scripts/shared_refs_sync.sh check

# Every skill packages cleanly into a valid, self-contained zip
bash neeve/scripts/skills_sync.sh check

# House-rules rendering, agent rendering, and hook-merge logic all still work
python3 neeve/scripts/test_context_render.py -v
python3 neeve/scripts/test_merge_house_rules.py -v
python3 neeve/scripts/test_agents_render.py -v
python3 neeve/scripts/test_merge_session_hook.py -v

# The routing table names every shipped skill; security.md/pm-lens.md/
# design-review.md citations are present
python3 neeve/scripts/check_org_sync.py
```

A finding from any of these is a line item to fix, not a warning to note
and move past — the same "a gap is a line item, not a silence" discipline
this repo asks of every product repo applies to itself first.

**Before opening a PR, also do a full local install smoke test** — this is
the one check CI doesn't run for you, since it needs a throwaway `$HOME`:

```bash
export HOME=$(mktemp -d)
bash neeve/install.sh --all
# confirm: every expected skill installed per tool, no stale/ghost agent
# files left behind, house rules rendered without a leaked {{PLACEHOLDER}}
```

---

## 6. Consistency rules learned the hard way

These are house rules for *this repo's own content*, distilled from real
corrections made while building it — apply them before someone has to
correct it again:

- **No external company names as attribution or lineage** ("(lineage:
  Google)" etc.) — principles are framed as SDLC-stage process principles,
  not credited to another company's internal practice.
- **Organize by SDLC/Design-Loop stage, not by department** (PRD/Design/
  Spec/Implementation/Review — not "PM principles" / "Engineering
  principles" / "Design principles" as separate silos).
- **No hardcoded repo names in generic docs or templates.** A doc meant to
  apply to any of the ~16 product repos should read the same whichever repo
  someone is in — name a real repo only in a context specifically about
  that repo (like a completed pilot report), never in a template or
  how-to-use guide.
- **No hardcoded heuristics standing in for a repo-shape assumption.** A
  repo might not be a backend/frontend service at all — don't bake in
  "openapi/routes/api" path detection as a default; make it opt-in
  (`git config`) or leave it to an agent's judgment, not a guess baked into
  a deterministic script.
- **Deterministic hooks stay deterministic.** Anything installed as a git
  hook or CI gate must never make a model call — surface mechanical facts
  only (a symbol was added, a file changed) and hand judgment calls (is
  this a contract change? a new feature? just a refactor?) to an
  agent-invoked skill, never guess at meaning in a no-model script.
- **State production consequence and gaps explicitly, every time** — an
  empty "Gaps" section is itself a finding unless it says what was checked.
  This applies to this repo's own PRs, not only to product-repo reviews.
- **A hardcoded list is a future bug.** Where a hardcoded name list (retired
  agents, contract paths, excluded dirs) can instead be derived or made
  config-driven, prefer that — `RETIRED_AGENTS` in `install.sh` is the one
  accepted exception (finite, well-documented, rarely changes); the skills
  manifest (§7 in `install.sh`) is the pattern to reach for instead of a new
  hardcoded list.

---

## 7. Related docs

- `neeve/README.md` — the 3-pillar architecture (4 Layers, Harness with
  Hooks, Design Loop) this guide assumes.
- `neeve/agent/README.md` — when to write an agent instead of a skill, and
  the per-tool rendering mechanics.
- `HOW-TO-USE.md` (repo root) — the engineer-facing setup/usage guide this
  repo produces; read it to see what an addition here actually looks like
  once installed.
