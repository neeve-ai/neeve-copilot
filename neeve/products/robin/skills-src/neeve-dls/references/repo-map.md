# Neeve DLS Repo Map

Use this reference only after the skill triggers.

## Repositories

- DLS repo: `/Users/shshah/Projects/src/neeve/dls-neeve`
- Shared fonts package: `/Users/shshah/Projects/src/neeve/fonts`

## High-Value Files

### DLS package structure

- `dls-neeve/src/components/`
  React component implementations.
- `dls-neeve/src/index.tsx`
  Public package entrypoint. It injects `src/index.css` via `injectCSS(css)` and re-exports components.
- `dls-neeve/src/index.css`
  DLS typography classes and CSS utilities.
- `dls-neeve/tailwind.config.js`
  Theme tokens, spacing scale, and `fontFamily` config.
- `dls-neeve/stories/components/`
  Component stories.
- `dls-neeve/stories/styleGuide/Typography.mdx`
  Typography token documentation.
- `dls-neeve/stories/styleGuide/`
  Color, spacing, iconography, shadows, and border-radius docs.
- `dls-neeve/README.md`
  Local workflow, package-consumption notes, font-package notes, reserved class-prefix rule, and commit message format.
- `dls-neeve/bitbucket-pipelines.yml`
  Publishing and version-bump flow.

### Fonts package structure

- `fonts/index.js`
  Imports the three family stylesheets exported by `@neeve/fonts`.
- `fonts/package.json`
  Publishes the package as `@neeve/fonts`.
- `fonts/SourceSans3/font-styles.css`
  `@font-face` declarations for Source Sans 3.
- `fonts/SourceSerif4/font-styles.css`
  `@font-face` declarations for Source Serif 4.
- `fonts/SourceCodePro/font-styles.css`
  `@font-face` declarations for Source Code Pro.

## Current Font Contract

### Family names used by DLS

- `Source Sans 3`
- `Source Serif 4`
- `Source Code Pro`

### Weights currently declared in shared CSS

- `Source Sans 3`: 400, 600, 700
- `Source Serif 4`: 400, 600
- `Source Code Pro`: 400, 700

### Tailwind font-family keys

In `dls-neeve/tailwind.config.js`:

- `SourceSans3: ["Source Sans 3"]`
- `SourceSerif4: ["Source Serif 4"]`
- `SourceCodePro: ["Source Code Pro"]`

## Visual Fidelity Rules

- Reuse DLS tokens and component patterns exactly. Do not swap in approximate spacing, color, typography, border, radius, or shadow values.
- Treat Storybook docs and existing DLS component implementations as the baseline visual contract.
- When updating a consuming page, prefer importing and configuring DLS components instead of hand-rolling lookalikes.
- Match all relevant states, not only default appearance:
  hover, focus, active, selected, disabled, loading, error, and empty states where applicable.

## Color And Component Verification

- Check the closest existing component story before changing a similar surface.
- For buttons and other interactive controls, verify the full token set:
  background, text color, border, icon color, hover state, focus ring, disabled treatment, and destructive/inactive variants when present.
- If a page-level surface must align to a DLS component example, copy the token usage from the DLS source rather than estimating values from memory.

## Typography Tokens

The Storybook typography guide documents these tokens for large and small breakpoints:

- `dls-page-title`
- `dls-page-heading`
- `dls-section-heading`
- `dls-callout-strong`
- `dls-callout`
- `dls-body-strong`
- `dls-body`
- `dls-code-strong`
- `dls-code`
- `dls-body-small-strong`
- `dls-body-small`
- `dls-caption-strong`
- `dls-caption`
- `dls-eyebrow`

Check both `stories/styleGuide/Typography.mdx` and `src/index.css` before changing any of them.

When editing typography, preserve:

- exact family
- exact weight
- exact size
- exact line height
- exact letter spacing
- exact transform or casing

## Common Tasks

### Add or modify a component

1. Edit the file in `dls-neeve/src/components/`.
2. Update or add the matching story in `dls-neeve/stories/components/`.
3. Export the component from `dls-neeve/src/index.tsx` if it is public.
4. Verify visual parity against the nearest existing DLS story or approved component pattern.

### Change typography or theme tokens

1. Update the CSS classes in `dls-neeve/src/index.css`.
2. Update theme wiring in `dls-neeve/tailwind.config.js` if the font or token mapping changes.
3. Update `dls-neeve/stories/styleGuide/Typography.mdx` to keep the docs truthful.
4. Re-check responsive definitions and rendered appearance after the token change.

### Change shared fonts

1. Edit the relevant family stylesheet in `fonts/<Family>/font-styles.css`.
2. Confirm `fonts/index.js` still imports the required families.
3. Check `fonts/package.json` if packaging changes are needed.

## Notes

- Consumers import DLS components from `@neeve/dls`.
- Consumers import fonts with `import "@neeve/fonts";`.
- The README states that class names prefixed with `dls-` are reserved.
- The README states that commit messages must follow:
  `<TICKET-NUMBER> [major|minor|patch] <message>`
- When visual certainty matters, run local app or Storybook surfaces and inspect them instead of relying on code review alone.
