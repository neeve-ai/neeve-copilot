# Summary (DLS component)

**Layer:** `@neeve/dls` design system primitive

Data summary display showing key-value pairs. Use for displaying structured metadata.

## When to use

- Connection details (protocol, port, hostname)
- Node information display
- Configuration summary
- Read-only data display
- Summary panels

## Props

| Prop        | Type                                         | Required | Notes                       |
| ----------- | -------------------------------------------- | -------- | --------------------------- |
| `items`     | `Array<{ label: string; value: ReactNode }>` | Yes      | Summary items to display    |
| `columns`   | `1 \| 2 \| 3`                                | No       | Column layout; default 2    |
| `className` | `string`                                     | No       | Additional Tailwind classes |

## Capabilities

- Displays label-value pairs in a structured layout.
- Supports multi-column layout (1, 2, or 3 columns).
- Values can be text, React nodes (icons, tags, links).

## Known limitations

- Read-only display—not for forms or editable data.
- No value formatting (numbers, dates)—page-local code must format values.
- Column layout is fixed (not responsive)—for responsive layout, use page-local CSS media queries.

## Ask before building if:

- Values should be editable—use form fields and `TextField`, not `Summary`.
- Date/number formatting is needed—format values before passing to component.
- Responsive columns needed (1 col on mobile, 2 on tablet)—add custom wrapper with CSS media queries.

## Accessibility floor

- Labels are associated with values semantically.
- Values can include interactive elements (links, buttons)—ensure they're keyboard-accessible.

## Example

```tsx
import { Summary } from "@neeve/dls";
import { Tag } from "@neeve/dls";

export function ConnectionSummary({ connection }: Props) {
  return (
    <Summary
      columns={2}
      items={[
        { label: "Hostname", value: connection.hostname },
        { label: "Port", value: connection.port },
        { label: "Protocol", value: connection.protocol },
        { label: "Status", value: <Tag label={connection.status} /> },
        { label: "Last updated", value: formatDate(connection.updatedAt) },
        { label: "Type", value: connection.systemType },
      ]}
    />
  );
}
```
