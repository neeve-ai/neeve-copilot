---
name: neeve-dls
description: Work with the `dls-neeve` design-system repository and the shared `fonts` package with pixel-perfect fidelity to the Neeve design system. Use when Codex needs to add or modify DLS React components, update exports, adjust Tailwind/theme tokens, change typography rules, wire Storybook docs or stories, or make font-package changes for Source Sans 3, Source Serif 4, or Source Code Pro, especially when visual parity with approved DLS components, spacing, colors, typography, and states is mandatory.
---

# Neeve DLS

Use this skill to make disciplined changes in the Neeve design system without re-discovering the repo layout, typography tokens, or shared font package. Default to exact DLS fidelity, not approximation.

**Two modes.** Default mode (below) targets `dls-neeve`/`fonts` themselves —
component, token, typography, and font-package work. **PRD Prototype Mode**
(see its own section further down) targets a *consuming* app instead, for
throwaway UI built from a `to-prd` PRD, on a disposable `proto/*` branch.
Confirm which mode applies before doing anything — if the task references a
PRD or a feature-slug rather than a DLS component/token, it's prototype mode.

## Start Here

**Before any edits**, confirm with the user where the repos live (or should be cloned). Ask:

> "Where should I find (or clone) `dls-neeve` and `fonts`? Default is `~/Projects/src/neeve/`. Press Enter to confirm or provide a different path."

Once the directory is confirmed (call it `$BASE`):

1. Pull the latest from Bitbucket:
   ```bash
   git -C $BASE/dls-neeve pull origin master 2>/dev/null || git -C $BASE/dls-neeve pull origin main
   git -C $BASE/fonts pull origin master 2>/dev/null || git -C $BASE/fonts pull origin main
   ```

2. If either repo is missing, clone it:
   ```bash
   git clone git@bitbucket.org:iotium/dls-neeve.git $BASE/dls-neeve
   git clone git@bitbucket.org:iotium/fonts.git $BASE/fonts
   ```

Then read [`references/repo-map.md`](references/repo-map.md) — substituting `$BASE` for all repo paths listed there — to choose the correct files for:

- component work in `dls-neeve`
- typography or token work in `dls-neeve`
- shared font-package work in `fonts`

## Workflow

1. Identify whether the task targets a component, a style token, Storybook documentation, or the shared fonts package.
2. Read only the relevant source files from the repo map instead of scanning the whole repository.
3. Preserve the current package pattern:
   `dls-neeve/src/index.tsx` injects `src/index.css` and re-exports public components.
4. Keep public surface changes coherent:
   update implementation, exports, and the closest Storybook story or style-guide page together.
5. For typography or font work, keep token names and family names aligned across:
   `tailwind.config.js`, `src/index.css`, Storybook typography docs, and the `fonts` package.
6. **Before marking any task done**, complete every step in the Visual Verification section — localhost boot, pixel-by-pixel comparison, Font Awesome icon check, all interactive states, and all breakpoints. Then emit the Visual Sign-off Checklist to the user (see bottom of this skill).

## Quality Bar

- Treat pixel-perfect fidelity as the default requirement because this skill is often used by non-frontend contributors while UX, design, and product validate the result.
- Match the DLS source exactly for component structure, spacing, radii, borders, shadows, icons, font family, font weight, line height, letter spacing, casing, and interaction states.
- Do not substitute near matches for DLS colors, typography, or spacing. If a button in DLS uses a specific background, foreground, border, hover, focus, disabled, or destructive token, use that exact token set.
- Do not improvise visual treatments that are merely similar. Prefer reusing an existing DLS component or token over recreating one by hand.
- When a design artifact or existing DLS example conflicts with local assumptions, trust the DLS implementation and docs first, then reconcile the consuming page to match them.
- Treat "close enough" as incorrect for DLS-facing work unless the user explicitly asks for a deliberate deviation.

## Visual Verification

Visual verification against a running localhost is **mandatory** for any change that affects rendered output. Reasoning from code alone is not sufficient.

### Localhost Requirement

1. Boot the local Storybook or app dev server before declaring any visual change done:
   ```bash
   # DLS Storybook
   cd $BASE/dls-neeve && npm run storybook
   # or consuming app
   npm run dev
   ```
2. Open the affected component or page in a browser at `localhost`.
3. Place the DLS reference (Storybook story or approved design artifact) side-by-side with the running page.
4. Zoom to 100% and compare **pixel by pixel**:
   - Spacing and padding match exactly (no off-by-one margins or gaps).
   - Border radius, border width, and shadow values are identical.
   - Colors match the exact DLS token — use the browser color picker to sample and verify hex values.
   - Font family, weight, size, line height, letter spacing, and text transform are identical.
   - Icon glyph, size, color, and alignment are identical (see Font Awesome rule below).
5. Repeat the comparison for every interactive state the component supports: hover, focus, active, pressed, selected, loading, error, disabled, and empty.
6. **Responsiveness** — resize the browser to every DLS breakpoint and verify at each:
   - Desktop (≥ 1280px), tablet (768px–1279px), and mobile (< 768px) — or the breakpoints defined in `tailwind.config.js`.
   - Layout, spacing rhythm, font scale, and component size must match the DLS spec at every breakpoint.
   - No overflow, truncation, wrapping, or alignment drift that is not present in the DLS reference.
   - Use the browser DevTools responsive mode to step through breakpoints; do not rely on a single viewport.

### Font Awesome Icon Rule

The DLS uses **Font Awesome** as its icon system. For every icon in a modified or new component:

- Use the exact Font Awesome class or component that the DLS reference uses — do not substitute a different icon set, SVG, or emoji.
- Verify the icon glyph renders at localhost and matches the reference visually.
- Confirm the icon's size token (`text-sm`, `text-base`, etc.), color token, and alignment class match the DLS story exactly.
- If an icon is missing from Font Awesome Free, check Font Awesome Pro before proposing an alternative; never use a visually similar but different glyph.

### Blocking Criteria

Do not mark a visual task done if any of the following are true at localhost:

- Any pixel offset, spacing difference, or color mismatch is visible at 100% zoom.
- An icon glyph, weight, or size differs from the DLS reference.
- Any interactive state has not been manually verified.
- The component has not been verified at every DLS breakpoint (desktop, tablet, mobile) when responsive styles exist.
- Layout, spacing, or font scale drifts at any breakpoint compared to the DLS reference.

If the localhost server cannot be started, say so explicitly and block the task — do not approve visual changes from code review alone.

## Component Changes

- Read the component in `dls-neeve/src/components/`.
- Read the matching story in `dls-neeve/stories/components/` when it exists.
- Confirm the component is exported from `dls-neeve/src/index.tsx`.
- Preserve existing naming and CSS-token usage instead of introducing ad hoc styles.
- Prefer composing or extending an existing DLS component over re-implementing the same pattern in a consuming app.
- Mirror the exact token usage from the closest approved DLS component when building a new variant or adjacent surface.

## Typography And Token Changes

- Treat `dls-neeve/src/index.css` as the source for DLS typography utility classes.
- Treat `dls-neeve/tailwind.config.js` as the source for font-family and theme token wiring.
- Treat `dls-neeve/stories/styleGuide/Typography.mdx` as the documentation contract for typography tokens.
- Keep desktop and small-screen definitions aligned when updating typography classes.
- Preserve exact family names, weights, line heights, letter spacing, and text transforms from the documented token definitions.
- Keep color-token usage consistent with the style-guide docs and existing component implementations.

## Font Package Changes

- Treat `$BASE/fonts` (confirmed with the user at the start) as a separate package published as `@neeve/fonts`.
- Update the relevant `font-styles.css` file for `@font-face` declarations.
- Keep `fonts/index.js` importing every family stylesheet that consumers need.
- Do not invent new family names; reuse `Source Sans 3`, `Source Serif 4`, and `Source Code Pro` exactly unless the task explicitly introduces a new family.

## Constraints

- Reserve the `dls-` class prefix for DLS-owned classes.
- Prefer minimal changes that match the existing Tailwind and shadcn-based patterns.
- If a change affects publishing or consumption, check the package README and pipeline files before changing the release flow.
- Do not accept "visually similar" replacements for official DLS components, font settings, or token values.

## Mode: PRD Prototype

Use this mode when the task consumes a `to-prd` PRD (`robin-adr/prds/
<feature-slug>.md`) and needs a throwaway, presentation-only UI to validate
it — not a `dls-neeve`/`fonts` change. This is new scope for this skill:
the target is a consuming app, not the design-system repo itself.

**Target repo: always ask, no default.** Confirm with the user:

> "Which repo does this prototype belong in — `robin-web` (most
> admin-portal-shaped PRDs) or `robin` (extension/sidepanel-specific
> features)? Default is neither — tell me which one."

**Branch:** `proto/<feature-slug>` — the exact slug from the PRD's header,
reused unchanged. This branch is **disposable and never merged to `main`**.
Say so explicitly to the user before starting. Keep it around until `to-erd`
has finished consuming it (Source-of-Truth references in the resulting
work-items doc may point at it), then it's safe to delete.

**Presentation-only, mocked data — no real backend wiring.** A prototype
proves the UI matches the PRD's journeys, not that the backend works. Mock
data and API responses rather than wiring real endpoints. A CI job,
`proto-branch-purity`, mirrors `robin-ai`'s `spec-branch-purity` job shape
and fails any `proto/*` PR that reaches real backend/API/schema files — the
inverse concern of the original (which blocks code changes on a docs-only
branch; this blocks real backend changes on a UI-only branch).

**Fidelity bar is lower than component work, and that's correct, not
sloppy.** Reuse existing DLS components and tokens exactly as normal DLS
fidelity requires (don't improvise new visual treatments here either), but
don't spend time on pixel-perfect polish for a throwaway — the point is
validating the PRD's journeys read correctly as a real screen, not shipping
production UI. Say this explicitly in the sign-off so nobody over-invests.

**Still run Visual Verification and still emit the Sign-off Checklist**
(below) when the prototype is ready for PM/design review — but extend it
with one more row:

```
| All PRD scenarios from robin-adr/prds/<feature-slug>.md represented (✅/❌ per scenario) | | |
```

Fill in one row per journey/scenario named in the PRD, not a single
pass/fail for the whole thing — a partial prototype should show exactly
which scenarios are covered and which aren't (this is the same gap-analysis
discipline every other agent/skill in this system applies, not new).

**Handoff:** once sign-off passes, the prototype (plus the PRD) is ready for
`to-erd`. State the `feature-slug` and the `proto/<feature-slug>` branch
name as the handoff.

## Visual Sign-off Checklist

This checklist is **mandatory**. Emit it in your response — filled in — before declaring any visual task done. Do not skip or abbreviate it. If any item cannot be confirmed, mark it ❌ and block the task with an explanation.

```
## Visual Sign-off

| Check | Status | Notes |
|---|---|---|
| Localhost server started and component rendered in browser | ✅ / ❌ | |
| DLS reference placed side-by-side at 100% zoom | ✅ / ❌ | |
| Spacing and padding match pixel-for-pixel | ✅ / ❌ | |
| Border radius, border width, and shadows identical | ✅ / ❌ | |
| Colors verified with browser color picker (exact hex match) | ✅ / ❌ | |
| Font family, weight, size, line height, letter spacing identical | ✅ / ❌ | |
| Font Awesome: exact glyph, size token, color, and alignment match | ✅ / ❌ / N/A | |
| All interactive states verified (hover, focus, active, disabled, error, …) | ✅ / ❌ / N/A | |
| Desktop breakpoint (≥ 1280px) verified | ✅ / ❌ | |
| Tablet breakpoint (768px–1279px) verified | ✅ / ❌ / N/A | |
| Mobile breakpoint (< 768px) verified | ✅ / ❌ / N/A | |
| No overflow, truncation, or alignment drift at any breakpoint | ✅ / ❌ | |

Production consequence & gaps:
- **Customer-visible consequence if this deviation ships:** [what an end user
  or operator would actually notice — a broken layout, an inaccessible
  control, a mismatched brand surface]
- **Breakpoints/states not yet verified:** [name them] — or "none, all rows above are ✅"
```

---

## Skill Chain

`neeve-dls` handles DLS component and font changes with pixel-perfect fidelity. It sits
between context gathering and review for any UI-facing task.

| Situation | Prior skill to run first |
|---|---|
| Unclear which DLS component or token to use | → `repo-ask` to trace existing usage in the consuming app |
| Task requires understanding the consuming app's layout before changing a component | → `repo-ask` on the consuming app first |
| PRD Prototype Mode | → `to-prd` agent (produces the PRD + feature-slug this mode consumes) |

| Situation | Next skill after visual sign-off passes |
|---|---|
| Change touches TypeScript, CSS, or component logic beyond token wiring | → `code-review` for code correctness |
| Change introduces a new DLS pattern not covered by an existing spec | → `to-spec` to document the new pattern |
| PRD Prototype Mode sign-off passes | → `to-erd` agent (turns the PRD + prototype into work items) |
| All visual checks and code review pass | → task is done |

**Feeds into:** `code-review` (always for logic changes), `to-spec` (new DLS patterns), `to-erd` (PRD Prototype Mode only)
**Fed by:** `repo-ask`, `implement-spec`, `to-prd` (PRD Prototype Mode only)

Load `references/quality-gates.md` — gates 1 (linter), 2 (type checker), 3 (unit tests),
and 7 (code-review) apply to every DLS code change regardless of scope.
