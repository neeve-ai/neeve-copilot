# LayoutGridContainer (DLS component)

**Layer:** `@neeve/dls` design system primitive

Grid layout container with responsive column configuration. Use for structured grid-based page layouts.

## When to use

- Dashboard card grids
- Multi-column layouts
- Responsive grid layouts
- Card-based content organization

## Props

| Prop        | Type               | Required | Notes                                      |
| ----------- | ------------------ | -------- | ------------------------------------------ |
| `children`  | `ReactNode`        | Yes      | Grid items                                 |
| `columns`   | `1 \| 2 \| 3 \| 4` | No       | Column count; default responsive           |
| `gap`       | `string`           | No       | Tailwind gap class (e.g., `"gap-dls-400"`) |
| `className` | `string`           | No       | Additional Tailwind classes                |

## Capabilities

- CSS Grid layout with responsive column configuration.
- Gap between grid items configurable via Tailwind gap classes.
- Auto-wraps items based on column count.

## Known limitations

- No support for custom grid areas or complex layouts—for complex grids, use page-local CSS Grid.
- No vertical alignment control—all items align to top of their grid cell.
- Column count is fixed; no automatic responsive breakpoints—use media queries or CSS Grid directly for responsive behavior.

## Ask before building if:

- Custom responsive breakpoints are needed (columns: 1 on mobile, 2 on tablet, 3 on desktop)—build page-local CSS Grid wrapper.
- Grid items should span multiple columns/rows—use page-local CSS Grid, not this component.
- Vertical centering or alignment is needed—add CSS via `className` (e.g., `items-center`).

## Accessibility floor

- Layout is semantic (`<div>` with CSS Grid).
- No impact on content accessibility.
- Ensures proper reading order via DOM order (not CSS Grid order property).

## Example

```tsx
import { LayoutGridContainer, Tile } from "@neeve/dls";

export function Dashboard({ cards }: Props) {
  return (
    <LayoutGridContainer columns={3} gap="gap-dls-400">
      {cards.map((card) => (
        <Tile key={card.id}>
          <h3>{card.title}</h3>
          <p>{card.description}</p>
        </Tile>
      ))}
    </LayoutGridContainer>
  );
}
```
