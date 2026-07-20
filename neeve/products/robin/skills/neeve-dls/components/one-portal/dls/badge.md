# Badge (DLS component)

**Layer:** `@neeve/dls` design system primitive

Small status indicator or count badge. Use for highlighting important information like notification counts.

## When to use

- Notification counts (unread messages: 3)
- Status indicators (Online/Offline)
- Small categorical labels
- New/Updated indicators
- Priority levels (High, Medium, Low)

## Props

| Prop        | Type                                                                  | Required | Notes                        |
| ----------- | --------------------------------------------------------------------- | -------- | ---------------------------- |
| `children`  | `ReactNode \| string`                                                 | Yes      | Badge content (text, number) |
| `variant`   | `"primary" \| "secondary" \| "success" \| "warning" \| "destructive"` | No       | Visual style                 |
| `className` | `string`                                                              | No       | Additional Tailwind classes  |

## Capabilities

- Displays small labeled status indicators with variant-specific styling and colors.
- Automatically applies semantic variant styling (success = green, warning = orange, destructive = red, etc.).
- Lightweight, non-interactive display component—no click handlers or state changes.

## Known limitations

- Not an interactive tag or chip—use `Tag` or `Chip` for dismissible elements.
- Does not support icons inline—if icon + label is needed, add custom markup in `children` or use `Tag` instead.
- Not a button or link—if a badge should be clickable, wrap it or use a different component.
- No tooltip on hover—if explanatory text is needed, add a `Tooltip` wrapper around `Badge` in page-local code.

## Ask before building if:

- The badge needs to be dismissible or interactive—use `Tag` or `Chip` instead.
- An icon needs to accompany the badge text—ask designer or use `Tag` which has icon support.
- The badge is clickable (e.g., "click to filter by status")—this should be a `Button` or wrapped link, not `Badge`.

## Accessibility floor

- `children` text is all that's announced—no special role attributes added.
- Variant (primary, success, warning) is visual only, not announced—if semantic meaning is critical, include it in `children` text (e.g., "Error: Database offline" instead of just "Database offline").

## Examples

### Notification badge

```tsx
import { Badge } from "@neeve/dls";

export function UserMenu({ unreadCount }: { unreadCount: number }) {
  return (
    <div className="relative">
      <button>Messages</button>
      {unreadCount > 0 && (
        <Badge variant="destructive" className="absolute -right-2 -top-2">
          {unreadCount}
        </Badge>
      )}
    </div>
  );
}
```

### Status badge

```tsx
import { Badge } from "@neeve/dls";

export function NodeCard({ node }: Props) {
  const variant = node.online ? "success" : "secondary";

  return (
    <div>
      <h3>{node.name}</h3>
      <Badge variant={variant}>{node.online ? "Online" : "Offline"}</Badge>
    </div>
  );
}
```
