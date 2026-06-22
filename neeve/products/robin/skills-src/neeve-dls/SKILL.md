---
name: neeve-dls
description: Work with the `dls-neeve` design-system repository and the shared `fonts` package with pixel-perfect fidelity to the Neeve design system. Use when Codex needs to add or modify DLS React components, update exports, adjust Tailwind/theme tokens, change typography rules, wire Storybook docs or stories, or make font-package changes for Source Sans 3, Source Serif 4, or Source Code Pro, especially when visual parity with approved DLS components, spacing, colors, typography, and states is mandatory.
---

# Neeve DLS

Use this skill to make disciplined changes in the Neeve design system without re-discovering the repo layout, typography tokens, or shared font package. Default to exact DLS fidelity, not approximation.

## Start Here

Read [`references/repo-map.md`](references/repo-map.md) before editing. Use it to choose the correct path for:

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
6. Validate the smallest meaningful surface:
   run targeted tests or build commands if present, and verify Storybook-facing changes when the task affects visual behavior.

## Quality Bar

- Treat pixel-perfect fidelity as the default requirement because this skill is often used by non-frontend contributors while UX, design, and product validate the result.
- Match the DLS source exactly for component structure, spacing, radii, borders, shadows, icons, font family, font weight, line height, letter spacing, casing, and interaction states.
- Do not substitute near matches for DLS colors, typography, or spacing. If a button in DLS uses a specific background, foreground, border, hover, focus, disabled, or destructive token, use that exact token set.
- Do not improvise visual treatments that are merely similar. Prefer reusing an existing DLS component or token over recreating one by hand.
- When a design artifact or existing DLS example conflicts with local assumptions, trust the DLS implementation and docs first, then reconcile the consuming page to match them.
- Treat "close enough" as incorrect for DLS-facing work unless the user explicitly asks for a deliberate deviation.

## Visual Verification

- Read the nearest Storybook story, style-guide doc, or existing DLS implementation before editing a UI surface.
- When a change can affect rendered output, inspect the result visually. Prefer local Storybook or the local app surface instead of reasoning from code alone.
- Boot local dev or Storybook servers when needed to confirm the page matches DLS expectations, including color, type scale, spacing rhythm, and state behavior.
- Compare hover, focus, pressed, selected, loading, error, and disabled states when the component supports them.
- If exact parity cannot be confirmed from available source artifacts, say so and identify what visual reference is missing instead of guessing.

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

- Treat `/Users/shshah/Projects/src/neeve/fonts` as a separate package published as `@neeve/fonts`.
- Update the relevant `font-styles.css` file for `@font-face` declarations.
- Keep `fonts/index.js` importing every family stylesheet that consumers need.
- Do not invent new family names; reuse `Source Sans 3`, `Source Serif 4`, and `Source Code Pro` exactly unless the task explicitly introduces a new family.

## Constraints

- Reserve the `dls-` class prefix for DLS-owned classes.
- Prefer minimal changes that match the existing Tailwind and shadcn-based patterns.
- If a change affects publishing or consumption, check the package README and pipeline files before changing the release flow.
- Do not accept "visually similar" replacements for official DLS components, font settings, or token values.
