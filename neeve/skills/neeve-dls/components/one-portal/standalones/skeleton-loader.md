# SkeletonLoader (standalone)

**Layer:** `shared/components` — standalone. Not in `@neeve/dls`. No DLS component
dependency; uses only Tailwind utility classes and DLS color tokens.

**Import:** default export.

```tsx
import SkeletonLoader from "@/shared/components/SkeletonLoader";
```

## When to use

As a loading placeholder that mimics the shape of content not yet loaded — individual
text lines, image thumbnails, card bodies, table cells, etc. Compose multiples to
approximate the layout of the incoming content.

Do **not** use for full-page loading states or spinner indicators — use DLS `Loader`
for those.

## Props

All props are optional. Every size and shape prop takes a **Tailwind utility class
string**, not a raw pixel/rem value.

| Prop           | Type      | Default                    | Notes                                                                                                                                                                    |
| -------------- | --------- | -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `width`        | `string`  | `"w-full"`                 | Any Tailwind width class: `"w-48"`, `"w-1/2"`, `"w-full"`, etc.                                                                                                          |
| `height`       | `string`  | `"h-4"`                    | Any Tailwind height class: `"h-3"`, `"h-6"`, `"h-12"`, etc.                                                                                                              |
| `borderRadius` | `string`  | `"rounded-md"`             | Any Tailwind border-radius class: `"rounded-full"` for circular avatars, `"rounded-none"` for sharp edges.                                                               |
| `color`        | `string`  | `"bg-background-tertiary"` | Must be a DLS semantic token Tailwind class — see Color below.                                                                                                           |
| `animation`    | `boolean` | `true`                     | When `true`, adds Tailwind `animate-pulse`. Set to `false` if the parent already controls animation or the user has reduced-motion preference handled at a higher level. |
| `className`    | `string`  | `""`                       | Escape hatch for additional Tailwind classes. Applied last so it can override defaults.                                                                                  |

### Color

The `color` prop must always be a DLS semantic token background class — never a raw
hex, arbitrary value, or non-DLS Tailwind color class. Prefer:

| Token class               | Use when                                                            |
| ------------------------- | ------------------------------------------------------------------- |
| `bg-background-tertiary`  | Default — neutral skeleton on a primary/secondary surface           |
| `bg-background-secondary` | Skeleton on a tertiary surface (panel, sidebar)                     |
| `bg-neutral-quarternary`  | Higher-contrast skeleton when `bg-background-tertiary` doesn't read |

## Capabilities

- Renders a single animated `<div>` — no markup, no semantic HTML, no JS logic.
- Composable: stack or grid multiple `SkeletonLoader`s to match any layout.
- Pulse animation via Tailwind `animate-pulse` (toggleable).

## Known limitations

- No built-in `aria-label` or `role` — accessibility attributes must be added by the
  consumer (see Accessibility below).
- Single block only — does not composite multiple shapes internally. Build multi-line
  or complex skeletons by rendering several instances.
- `animation` prop disables the pulse globally on the element but does not respond to
  the user's `prefers-reduced-motion` OS preference automatically — the consumer is
  responsible for passing `animation={false}` when needed.

## Accessibility floor

`SkeletonLoader` renders a plain `<div>` with no semantic meaning. The consumer must
handle accessible loading announcements at the container level:

```tsx
// Wrap the skeleton group with a region that announces loading state
<div role="status" aria-label="Loading content" aria-live="polite">
  <SkeletonLoader height="h-5" width="w-3/4" />
  <SkeletonLoader height="h-5" width="w-1/2" className="mt-2" />
</div>
```

When the real content replaces the skeleton, the `role="status"` container should
also be replaced or its label updated so screen readers announce completion.

## Example

```tsx
import SkeletonLoader from "@/shared/components/SkeletonLoader";

// Single text-line placeholder
<SkeletonLoader height="h-5" width="w-48" />

// Avatar circle
<SkeletonLoader
  width="w-10"
  height="h-10"
  borderRadius="rounded-full"
/>

// Card body (three lines at different widths)
<div role="status" aria-label="Loading card" className="dls-flex dls-flex-col dls-gap-200">
  <SkeletonLoader height="h-5" width="w-full" />
  <SkeletonLoader height="h-5" width="w-3/4" />
  <SkeletonLoader height="h-5" width="w-1/2" />
</div>

// Static placeholder (no pulse) — e.g. when parent handles animation
<SkeletonLoader height="h-8" width="w-full" animation={false} />
```
