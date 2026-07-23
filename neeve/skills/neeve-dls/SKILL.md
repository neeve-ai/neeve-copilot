---
name: neeve-dls
description: Work with the `dls-neeve` design-system repository and the shared `fonts` package with pixel-perfect fidelity to the Neeve design system. Use when Codex needs to add or modify DLS React components, update exports, adjust Tailwind/theme tokens, change typography rules, wire Storybook docs or stories, or make font-package changes for Source Sans 3, Source Serif 4, or Source Code Pro, especially when visual parity with approved DLS components, spacing, colors, typography, and states is mandatory. Also use when building, prototyping, or wiring UI *inside the `one-portal` product* — a consuming app of `@neeve/dls` — since correct component resolution (DLS vs. `shared/components` wrapper vs. standalone vs. page-local) matters there just as much as library fidelity does here (see Mode: Product Consumption).
---

# Neeve DLS

Use this skill to make disciplined changes in the Neeve design system without re-discovering the repo layout, typography tokens, or shared font package. Default to exact DLS fidelity, not approximation.

**Three modes.** Default mode (below) targets `dls-neeve`/`fonts` themselves —
component, token, typography, and font-package work. **PRD Prototype Mode**
(see its own section further down) targets a *consuming* app instead, for
throwaway UI built from a `to-prd` PRD, on a disposable `proto/*` branch.
**Mode: Product Consumption (one-portal)** (further down still) targets the
`one-portal` product — also a consuming app, but persistent production work,
not a throwaway prototype. Confirm which mode applies before doing anything:
- References `dls-neeve`/`fonts` source directly → default mode.
- References a PRD/feature-slug, targets `robin-web`/`robin`, and is
  explicitly disposable → PRD Prototype Mode.
- Names `one-portal`, or a route/feature/screen in that product → Mode:
  Product Consumption.

## Start Here

**Before any edits**, locate the repos on *this* machine by searching — do
not assume a fixed path (there is no default like `~/Projects/src/neeve/`;
that is one engineer's layout, not a guarantee). The expected setup is a
single **product workspace** with all of that product's repos checked out
side by side, so agents can read across them for the full picture instead of
guessing at a contract. The design system (`dls-neeve` + `fonts`) is shared —
whichever product's workspace you are in that consumes DLS will have them as
siblings.

Discover the workspace root by walking up from the current directory:

```bash
# $BASE = the workspace root holding the design-system repos as siblings.
find_base() {
  local dir; dir="$(pwd)"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/dls-neeve/.git" ] && [ -d "$dir/fonts/.git" ]; then
      echo "$dir"; return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}
BASE="$(find_base)" || true
```

Assess which product this workspace belongs to before proceeding: match the
sibling repos present against the known-products registry
(`neeve/products/*/context/product-overview.md`) and read that product's
overview so the persona and problem statement are grounded, not assumed. If
the workspace matches no known product, say so rather than guessing.

If `find_base` finds nothing, **do not clone into a guessed path and do not
invent a location** — the design-system repos missing from the workspace
usually means the session was started without them. Stop and ask the user to
relaunch with the full product workspace:

> "I can't see `dls-neeve` and `fonts` as sibling repos from here. This skill
> needs them (and ideally the rest of the product's repos) checked out
> together in one workspace so I can read across them without assuming.
> Please start the session from a workspace that has them, or tell me the
> workspace root that does."

Once `$BASE` is known, pull the latest before editing:

```bash
git -C "$BASE/dls-neeve" pull origin master 2>/dev/null || git -C "$BASE/dls-neeve" pull origin main
git -C "$BASE/fonts" pull origin master 2>/dev/null || git -C "$BASE/fonts" pull origin main
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
- For a design *review* (not implementation) of a customer-facing surface, apply `neeve/references/design-review.md` in full — it adds accessibility-as-compliance-surface and failure-state-designed-first checks this skill's own implementation workflow doesn't independently gate on.

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
- If a change depends on how Tailwind, shadcn, or a font-loading mechanism
  actually behaves in the version this package pins (not the version
  remembered from training data), invoke `debug-trace` to ground it before
  changing publish/consumption code — a token or build change made on a
  wrong belief about the underlying tool ships to every consumer of
  `@neeve/dls`. Include the **Depth check** line (`debug-trace`'s Disclosure
  Requirement) in the change summary.

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

## Mode: Product Consumption (one-portal)

Use this mode when the task is building, prototyping, mocking up, or wiring a
screen, page, form, table, or any UI piece **inside the `one-portal` product**
— even if the request just says "use the DLS" or names a component casually
("add a button here", "put this in a table", "use the dialog component").
Unlike PRD Prototype Mode, this is **persistent product work that ships**,
not a disposable prototype on a `proto/*` branch — hold it to `one-portal`'s
real coding standards and quality gates, not a lowered fidelity bar.

`one-portal` has three layers of UI code, and almost every quality problem in
this mode traces back to guessing which layer something belongs to instead of
checking:

```
1. @neeve/dls          →  the design system package. Bare, unopinionated components.
2. shared/components   →  two kinds of product-specific components:
                            • Wrappers  — extend a DLS primitive with product logic
                                          (e.g. TableV2, LoadingButton).
                            • Standalones — not in the DLS for deliberate design or
                                          engineering reasons; built exclusively for
                                          one-portal (e.g. StepperTabs, SkeletonLoader).
3. page-local code     →  layout only (grid/flex), written directly in the feature folder.
                          Never a place to reinvent something that already exists above.
```

Any request for a table — including "use the table from the DLS" — must
resolve to `TableV2`. The bare DLS `Table` primitive is an internal
dependency of `TableV2` and is never used directly in `one-portal`. **Never
skip the resolution step below.**

### Step 1 — Resolve the component

For every UI element in the request, read
[`references/one-portal-component-resolution.md`](references/one-portal-component-resolution.md)
and [`components/one-portal/INDEX.md`](components/one-portal/INDEX.md) to
find which layer it belongs to:

- Look it up in `components/one-portal/INDEX.md` first — it maps
  plain-language asks ("table", "dropdown", "modal", "search box") to the
  correct component and layer.
- If it's a DLS component, open its file in `components/one-portal/dls/`.
- If it's a `shared/components` wrapper, open its file in
  `components/one-portal/wrappers/`.
- If it's a `shared/components` standalone, open its file in
  `components/one-portal/standalones/`.
- If it isn't in the index at all, it may be genuinely page-local (layout) or
  it may be a gap in this mode's coverage — say so explicitly rather than
  silently inventing a component. See "Unknown components" below.

Never assume a component comes from the DLS just because it's visual and
reusable-looking. `shared/components` exists precisely because some things
are intentionally *not* in the DLS.

### Step 2 — Check whether the ask fits what the component can actually do

Every component file lists **capabilities** and **known limitations**. Before
writing code:

1. Compare the request against the limitations list.
2. If the request exceeds what the component supports, **do not** build a
   one-off replacement or bolt extra logic onto the consuming page to fake the
   missing behavior. Instead, stop and tell the user, e.g.:

   > "TableV2 doesn't currently support nested/expandable rows. Do you want me
   > to extend `shared/components/table/TableV2.tsx` to add that first, and
   > then build this on top of it — or would you rather scope this without
   > row expansion for now?"

   This keeps the wrapper layer as the single source of truth instead of
   accumulating page-local special cases that drift from it.

### Step 3 — Fill in every required prop before writing code

Each component file has a props table with a `required` column. Before
generating code:

- If a required prop's value isn't given or inferable from the conversation,
  ask for it.
- If the component has meaningfully different variants (e.g. Button:
  primary/secondary/ghost), and the request doesn't specify one, ask which
  variant — don't default silently.
- Batch these into one clarifying turn (all missing props/variants at once).
  See
  [`references/one-portal-clarification-protocol.md`](references/one-portal-clarification-protocol.md)
  for exactly when to ask vs. when a documented default is safe to use.

### Step 4 — Use the correct design tokens

Never hardcode a hex color, a pixel spacing value, or a font-family/size.
Read
[`references/one-portal-design-tokens.md`](references/one-portal-design-tokens.md)
for how typography, color, and spacing classes map to intent (e.g.
destructive action → `--danger-*` tokens, not a raw red). This applies inside
page-local layout code just as much as inside components.

### Step 5 — Follow one-portal's own coding standards

Read
[`references/one-portal-coding-standards.md`](references/one-portal-coding-standards.md)
for folder structure, file naming, import ordering, and component composition
patterns specific to `one-portal`. Code that uses the right components but
doesn't look like it belongs in the codebase is still a compliance failure.

### Step 6 — Build responsively and accessibly by default

Every component file notes the a11y contract it already provides (e.g. DLS
`Button` already handles focus rings and `aria-disabled`) versus what the
consumer is responsible for (e.g. providing an `aria-label` when using
`Button` in icon-only mode, correct heading hierarchy, keyboard navigation
for anything page-local). Treat the notes as the floor, not the ceiling. Also
check responsiveness against `one-portal`'s real breakpoints — see
`references/one-portal-design-tokens.md`.

### Unknown components

If a request names something that isn't in `components/one-portal/INDEX.md`
and doesn't look like plain layout, say so plainly: "I don't have this
documented yet — is this a DLS component, a `shared/components` wrapper, a
`shared/components` standalone, or something new?" Do not guess and do not
silently fall back to building a bespoke component. Flag it so the index can
be extended.

### Compliance Sign-off (one-portal mode)

Emit this checklist, filled in, before declaring any `one-portal` UI task
done:

```
## Compliance Sign-off
| Check | Status | Notes |
|---|---|---|
| Every component resolved to DLS / wrapper / page-local (none guessed) | ✅ / ❌ | |
| No component used beyond its documented capabilities | ✅ / ❌ | |
| All required props supplied (asked for anything missing) | ✅ / ❌ | |
| Typography / color / spacing use DLS tokens only, no hardcoded values | ✅ / ❌ | |
| Folder/file structure and naming match one-portal-coding-standards.md | ✅ / ❌ | |
| Responsive behavior checked at one-portal breakpoints | ✅ / ❌ | |
| Accessibility floor met (labels, focus, keyboard, heading hierarchy) | ✅ / ❌ | |
```

Code placed in `shared/` must also have accompanying tests per
`references/one-portal-coding-standards.md`'s Testing Expectations — this
mode's sign-off does not substitute for `implement-spec`'s quality gates on
any code that isn't a design-only handoff.

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
| Mode: Product Consumption (one-portal), and the request names an undocumented component | → flag as unknown per that mode's "Unknown components" section rather than running another skill |

| Situation | Next skill after visual sign-off passes |
|---|---|
| Change touches TypeScript, CSS, or component logic beyond token wiring | → `code-review` for code correctness |
| Change introduces a new DLS pattern not covered by an existing spec | → `to-spec` to document the new pattern |
| PRD Prototype Mode sign-off passes | → `to-erd` agent (turns the PRD + prototype into work items) |
| Mode: Product Consumption (one-portal) compliance sign-off passes, and code was placed in `shared/` | → `implement-spec`'s quality gates apply, then `code-review` |
| All visual checks and code review pass | → task is done |

**Feeds into:** `code-review` (always for logic changes), `to-spec` (new DLS patterns), `to-erd` (PRD Prototype Mode only), `implement-spec` (Product Consumption mode, `shared/` code only)
**Fed by:** `repo-ask`, `implement-spec`, `to-prd` (PRD Prototype Mode only)

Load `references/quality-gates.md` — gates 1 (linter), 2 (type checker), 3 (unit tests),
and 7 (code-review) apply to every DLS code change regardless of scope.
