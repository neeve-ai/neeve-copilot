## Design System — `dls-neeve` Is Mandatory, Pixel-Perfect, No Exceptions

This repo renders user-facing UI. Every visual element — typography, color,
spacing, icons, components, and flows — must match `dls-neeve` (`@neeve/dls`)
**pixel-perfect, to the tee, every time**. This repo currently depends on
Radix UI directly for some components; that is exactly the kind of duplicate,
drifting-from-DLS primitive this rule exists to stop. Treat any new
hand-built component or ad hoc style as a defect, not a shortcut.

- **Typography, color, spacing tokens, and fonts** (Source Sans 3, Source
  Serif 4, Source Code Pro) are owned by `dls-neeve` and the shared `fonts`
  package. Hardcoding a font family, weight, line-height, letter-spacing, or
  a color/spacing value that already has a DLS token is not acceptable —
  use the token.
- **Components**: buttons, dialogs, dropdowns, tooltips, avatars, form
  controls, and every other UI primitive must come from `dls-neeve`, not be
  rebuilt on `@radix-ui/*` directly. "Close enough" is incorrect. Do not
  improvise a visual treatment that is merely similar — match structure,
  spacing, radii, borders, shadows, icons, and every interaction state
  (hover, focus, disabled, destructive) exactly. If DLS doesn't yet have what
  you need, that is a gap to close in `dls-neeve` itself or flag explicitly —
  never a license to build a local approximation.
- **Flows** (empty states, loading states, multi-step forms, navigation
  patterns) must match an existing `dls-neeve` Storybook pattern exactly
  before a new one is invented.
- **Assets** (icons, illustrations) must use the exact icon set and version
  DLS standardizes on — not an independently pinned Font Awesome version.
- When a design artifact or existing DLS example conflicts with a local
  assumption in this repo, the DLS implementation and docs win — reconcile
  this repo to match DLS, not the other way around.

Use the `neeve-dls` skill (`/neeve-dls` or `$neeve-dls`) for every DLS-facing
change. It is non-negotiable to complete its full Visual Verification
workflow (localhost boot, pixel-by-pixel comparison, Font Awesome icon check,
every interactive state, every breakpoint) and emit its Visual Sign-off
Checklist before marking any UI change done — "reasoning from code alone" is
explicitly insufficient per that skill.
