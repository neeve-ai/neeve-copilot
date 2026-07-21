# Separator (DLS component)

**Layer:** `@neeve/dls` design system primitive

Visual divider line. Use to separate sections or groups of content.

## When to use

- Dividing form sections
- List item separators
- Visual grouping of content
- Breaking up dense information
- Between card rows or sections

## Props

| Prop          | Type                         | Required | Notes                             |
| ------------- | ---------------------------- | -------- | --------------------------------- |
| `orientation` | `"horizontal" \| "vertical"` | No       | Direction; default `"horizontal"` |
| `className`   | `string`                     | No       | Additional Tailwind classes       |

## Capabilities

- Horizontal or vertical divider line using semantic `<hr>` or styled div.
- Respects design tokens for color and spacing.

## Known limitations

- Does not support custom styling beyond className—for complex separators (dashed, gradient), use custom CSS.
- Pure decoration; no accessibility impact (semantic `<hr>` is hidden from screen readers by default).

## Ask before building if:

- Dashed or custom-styled separator is needed—build custom component or add CSS via `className`.
- Separator should have visible label or text on it—use custom component, not `Separator` primitive.

## Accessibility floor

- Separator is purely decorative (not announced by screen readers).
- Use `<hr>` semantically for content divisions if needed for document structure.

## Examples

### Horizontal separator between sections

```tsx
import { Separator } from "@neeve/dls";

export function NetworkForm() {
  return (
    <form>
      <div>
        <h3>Basic Information</h3>
        {/* form fields */}
      </div>

      <Separator className="my-dls-600" />

      <div>
        <h3>Advanced Settings</h3>
        {/* more form fields */}
      </div>
    </form>
  );
}
```

### Vertical separator

```tsx
import { Separator } from "@neeve/dls";

export function HeaderActions() {
  return (
    <div className="gap-dls-300 flex items-center">
      <button>Edit</button>
      <Separator orientation="vertical" />
      <button>Delete</button>
    </div>
  );
}
```

### Used in one-portal: WANConnectionDetails.tsx

```tsx
<Separator />
```
