# Avatar (DLS component)

**Layer:** `@neeve/dls` design system primitive

Small circular image container for profile pictures, user avatars, and org logos.

## When to use

- User profile pictures in headers, dropdowns, or user lists
- Org logo display in branding sections
- Small circular images where a border + fixed dimensions are needed

## Props

| Prop        | Type                             | Required | Notes                                   |
| ----------- | -------------------------------- | -------- | --------------------------------------- |
| `src`       | `string`                         | Yes      | Image URL                               |
| `alt`       | `string`                         | Yes      | Accessibility text describing the image |
| `size`      | `"small" \| "medium" \| "large"` | No       | Default `"medium"`                      |
| `className` | `string`                         | No       | Additional Tailwind classes             |

## Capabilities

- Handles circular image containers with fixed aspect ratio and border styling.
- Supports three size variants (small, medium, large) for flexible layout integration.
- Gracefully handles broken image URLs (no special error state UI—falls back to browser default).

## Known limitations

- No fallback avatar (placeholder, initials, color)—if a fallback is needed (e.g., when `src` is missing), add a fallback image or use a custom component wrapping `Avatar`.
- Does not support multiple images or image compositing (e.g., two overlapping avatars for co-owners).
- Not a button or clickable element—wrap in a `<button>` or use as a visual element in a `RowCard` if clickability is needed.

## Ask before building if:

- A fallback (placeholder, initials, colored background) is needed when no image URL exists—confirm if this should be added in page-local code or if a wrapper component should be built.
- The avatar is part of a clickable row/card—ensure it's placed within a `RowCard` or similar container, not as a standalone button.
- Multiple avatars need to be layered or composed (e.g., "3 users")—this requires page-local layout, not a component feature.

## Accessibility floor

- `alt` prop is required and must describe the image ("Organization logo" or "John Doe's avatar").
- The component does not add `role="img"` automatically; if used as a decorator, wrap in a presentational container.

## Examples

### Basic org logo

```tsx
import { Avatar } from "@neeve/dls";

export function OrgLogoDisplay({ logoUrl }: { logoUrl: string }) {
  return <Avatar src={logoUrl} alt="Organization logo" size="large" />;
}
```

### User profile pic in header

```tsx
import { Avatar } from "@neeve/dls";

export function UserHeader({
  user,
}: {
  user: { name: string; avatarUrl: string };
}) {
  return (
    <div className="gap-dls-200 flex items-center">
      <Avatar
        src={user.avatarUrl}
        alt={`${user.name}'s profile`}
        size="small"
      />
      <span>{user.name}</span>
    </div>
  );
}
```
