# Drawer (DLS component)

**Layer:** `@neeve/dls` design system primitive

Slide-out sidebar panel, typically from the left or right edge. Use for secondary navigation or detailed views without leaving the current context.

## When to use

- Side filter panels
- Detail panels that overlay the main content
- Navigation drawers
- Secondary actions panel

## Props (similar to Dialog)

| Prop           | Type                      | Required | Notes                                           |
| -------------- | ------------------------- | -------- | ----------------------------------------------- |
| `open`         | `boolean`                 | Yes      | Controls open/close state                       |
| `onOpenChange` | `(open: boolean) => void` | Yes      | Callback when user closes                       |
| `title`        | `string`                  | No       | Header text                                     |
| `children`     | `ReactNode`               | Yes      | Drawer content                                  |
| `side`         | `"left" \| "right"`       | No       | Which side drawer slides from; default `"left"` |
| `className`    | `string`                  | No       | Additional Tailwind classes                     |

## Capabilities

- Handles open/close state, backdrop click, and focus management.
- Slides in from specified side (left/right) with overlay.
- Supports header (title) and full custom content body.

## Known limitations

- Does not provide internal scrolling—if drawer content is taller than viewport, wrap in a scrollable container in page-local code.
- Does not stack multiple drawers—if nested drawers are needed, this is typically a UX issue; clarify with designer.
- No built-in "back" navigation—if a drawer should open another drawer, manage state and component swapping in page-local code.

## Ask before building if:

- The drawer content is very tall—confirm if it should scroll internally, or if content should be paginated/filtered.
- Multiple drawers need to stack or nest—clarify if this is a workflow issue that should be solved differently (tabs, accordion, etc.).
- The drawer is part of a larger form—confirm if validation and submission should close the drawer or stay open.

## Accessibility floor

- `title` is announced when drawer opens.
- Focus management is handled (moves to drawer on open).
- Escape key closes the drawer.
- Backdrop click closes it.

## Example

```tsx
import { Drawer, Button } from "@neeve/dls";
import { useState } from "react";

export function ListWithDetailDrawer({ items }: Props) {
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [selectedItem, setSelectedItem] = useState(null);

  return (
    <>
      <div className="gap-dls-400 grid grid-cols-4">
        {items.map((item) => (
          <button
            key={item.id}
            onClick={() => {
              setSelectedItem(item);
              setDrawerOpen(true);
            }}
          >
            {item.name}
          </button>
        ))}
      </div>

      {selectedItem && (
        <Drawer
          open={drawerOpen}
          onOpenChange={setDrawerOpen}
          title={selectedItem.name}
          side="right"
        >
          <ItemDetails item={selectedItem} />
        </Drawer>
      )}
    </>
  );
}
```
