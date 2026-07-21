# Component Resolution

The reason prototypes drift from one-portal's real UI is almost always a resolution
mistake, not a styling mistake. Get this right and most of the rest follows.

## The three layers

### 1. `@neeve/dls`

The design system package. Source of truth: the private Bitbucket repo `dls-neeve`
(see this skill's default mode if you ever need to inspect or modify the DLS source
itself — that mode is for maintaining the library, this mode is for consuming it).

DLS components are intentionally minimal. They give you the visual contract (styling,
tokens, base a11y) and not much product logic. Example: DLS `Table` renders
`TableHeader`/`TableBody`/`TableRow`/`TableCell` — no sorting, no column resize, no
persistence. That's by design, not a gap.

### 2. `shared/components` (one-portal repo)

This layer contains **two distinct kinds** of components — do not assume everything
here is a DLS wrapper:

**Wrappers** extend a DLS primitive with product-specific logic that is too complex or
too specific to belong in a generic design system: state management, persistence,
interaction patterns, etc. Examples: `TableV2` (wraps DLS `Table`), `LoadingButton`
(wraps DLS `Button`).

**Standalones** are components that were built directly in one-portal and do not exist
in the DLS — not because they're missing, but because they were deliberately kept
out of the design system (product-specific UX pattern, insufficient reuse across
products, or engineering scope decision). Examples: `StepperTabs`, `SkeletonLoader`.

**This is the layer the design team doesn't know exists.** Any request for a table —
static or interactive, simple or complex — must resolve to `TableV2`. The bare DLS
`Table` is an internal dependency of `TableV2` and is never used directly in
one-portal product code.

### 3. Page-local code

Grid/flex layout, page composition, feature-specific glue. Written directly in the
feature folder. This layer should never contain a hand-rolled reimplementation of
something that already exists in layers 1 or 2 — if you find yourself writing
column-resize logic in a page component, stop, that belongs in `TableV2`, not here.

## Resolution algorithm

For each UI element named or implied in the request:

1. Check `components/one-portal/INDEX.md` for a name/synonym match.
2. If matched to a DLS entry → open `components/one-portal/dls/<name>.md`.
3. If matched to a `shared/components` wrapper entry → open `components/one-portal/wrappers/<name>.md`.
4. If matched to a `shared/components` standalone entry → open `components/one-portal/standalones/<name>.md`.
5. If the match is ambiguous → default to the `shared/components` entry if one exists,
   and say so explicitly rather than silently picking.
6. If no match exists → do not guess. Flag as unknown (see SKILL.md "Unknown
   components") rather than inventing markup that merely looks plausible.

## Why "looks like a component" isn't enough

A visually reusable-looking block does not imply it's a DLS component. Plenty of
one-portal patterns (page headers, filter bars, specific empty states) are page-local
or `shared/components` precisely because they're one-portal-specific, not
general-purpose design-system material. Never infer "this must be in the DLS" from
visual polish alone — always confirm via the index.
