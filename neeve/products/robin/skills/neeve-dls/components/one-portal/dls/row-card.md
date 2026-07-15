# RowCard (DLS component)

**Layer:** `@neeve/dls` design system primitive

Styled card for list-style rows. Use in vertical lists where each row is a distinct card/item.

## When to use

- List items (users, endpoints, nodes in a vertical list)
- Item cards with consistent styling
- List item containers
- Cards that look like rows

## Props

| Prop        | Type         | Required | Notes                              |
| ----------- | ------------ | -------- | ---------------------------------- |
| `children`  | `ReactNode`  | Yes      | Card content                       |
| `onClick`   | `() => void` | No       | Click handler for navigation       |
| `selected`  | `boolean`    | No       | Visual selection state             |
| `actions`   | `ReactNode`  | No       | Right-side actions (buttons, menu) |
| `className` | `string`     | No       | Additional Tailwind classes        |

## Capabilities

- Displays row as a card with hover affordance (if `onClick` provided).
- Supports selection state highlighting (when `selected={true}`).
- Optional right-side action slot for buttons/menus.
- Flexible content layout via `children`.

## Known limitations

- No checkbox integration—if bulk selection is needed, add `Checkbox` to children and use `BulkActionBar`.
- Does not auto-select on click—`onClick` is just a callback; page-local code manages `selected` state.
- Actions slot layout is not constrained; actions must have consistent width.

## Ask before building if:

- Row selection with bulk actions needed—add `Checkbox` to children, pair with `BulkActionBar`.
- Row should have keyboard shortcuts (e.g., 'd' to delete)—add page-local key listeners.
- Drag-and-drop reordering needed—add page-local dnd library (react-beautiful-dnd, etc.).

## Accessibility floor

- If `onClick` provided, ensure row is semantic (use `<button>` or `<a>` if navigation).
- `selected` state is visually clear (contrast/highlighting).
- Actions slot must contain accessible buttons/links.
- Use `aria-selected` if mimicking selectable list behavior.

## Example

```tsx
import { RowCard } from "@neeve/dls";
import { Button } from "@neeve/dls";

export function UsersList({ users }: Props) {
  return (
    <div className="gap-dls-200 flex flex-col">
      {users.map((user) => (
        <RowCard
          key={user.id}
          onClick={() => navigateToUser(user.id)}
          actions={
            <Button variant="secondary" size="sm">
              Edit
            </Button>
          }
        >
          <div>
            <h4>{user.name}</h4>
            <p className="text-foreground-secondary text-sm">{user.email}</p>
          </div>
        </RowCard>
      ))}
    </div>
  );
}
```
