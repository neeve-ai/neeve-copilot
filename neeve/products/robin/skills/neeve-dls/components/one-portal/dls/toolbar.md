# Toolbar (DLS component)

**Layer:** `@neeve/dls` design system primitive

Horizontal bar with action buttons and controls. Use for page-level or table-level toolbars.

## When to use

- Table toolbar (view, export, filter buttons)
- Page-level action buttons
- Grouped controls and toggles
- Tool palettes

## Props

| Prop          | Type                         | Required | Notes                                    |
| ------------- | ---------------------------- | -------- | ---------------------------------------- |
| `children`    | `ReactNode`                  | Yes      | Toolbar items/buttons                    |
| `orientation` | `"horizontal" \| "vertical"` | No       | Layout direction; default `"horizontal"` |
| `className`   | `string`                     | No       | Additional Tailwind classes              |

## Capabilities

- Horizontal or vertical container for grouping action buttons and controls.
- Flexible layout for mixing buttons, separators, toggles, and other UI elements.
- Semantic container (no special affordances, pure layout).

## Known limitations

- No built-in spacing or alignment—child elements must be spaced via gap/margin utilities.
- No overflow handling for many buttons—if many buttons exceed space, use `Menubar` or custom scrollable toolbar.
- Purely a layout container; no state management.

## Ask before building if:

- Many buttons will appear (10+)—clarify if grouping via `Menubar` or scrollable toolbar is needed.
- Vertical alignment/centering is needed—add flexbox utilities via `className` (e.g., `items-center`).

## Accessibility floor

- Toolbar itself has no semantic role (it's a container).
- Child buttons and controls are individually accessible.
- Ensure buttons have descriptive labels or `aria-label`.

## Example

```tsx
import { Toolbar, Button, Separator } from "@neeve/dls";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faRefresh, faFileExport, faGear } from "@view/pro-regular-svg-icons";

export function TableToolbar() {
  return (
    <Toolbar className="gap-dls-200 p-dls-300 flex items-center border-b">
      <Button variant="secondary" size="sm">
        <FontAwesomeIcon icon={faRefresh} />
      </Button>
      <Separator orientation="vertical" />
      <Button variant="secondary" size="sm">
        <FontAwesomeIcon icon={faFileExport} /> Export
      </Button>
      <Button variant="secondary" size="sm">
        <FontAwesomeIcon icon={faGear} />
      </Button>
    </Toolbar>
  );
}
```
