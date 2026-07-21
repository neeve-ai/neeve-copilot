# Popover (DLS component)

**Layer:** `@neeve/dls` design system primitive

Floating panel anchored to an element. Use for optional secondary content or actions.

## When to use

- Inline help or additional context
- Small forms within popovers
- Anchored dropdowns with rich content
- Quick inline actions

## Props

| Prop           | Type                                     | Required | Notes                                |
| -------------- | ---------------------------------------- | -------- | ------------------------------------ |
| `open`         | `boolean`                                | Yes      | Open/close state                     |
| `onOpenChange` | `(open: boolean) => void`                | Yes      | State callback                       |
| `content`      | `ReactNode`                              | Yes      | Popover content                      |
| `children`     | `ReactNode`                              | Yes      | Trigger element                      |
| `side`         | `"top" \| "right" \| "bottom" \| "left"` | No       | Popover position; default `"bottom"` |

## Capabilities

- Floating panel anchored to trigger element with automatic positioning.
- Handles click outside to close, and keyboard navigation (Escape).
- Prevents popover from going off-screen (auto-repositions if needed).

## Known limitations

- Does not provide scroll handling for tall content—if popover content exceeds viewport height, wrap in a scrollable container.
- No automatic width sizing—if content is very wide, provide explicit width via inline styles or wrapper `className`.
- Not a dropdown select—use `Select`, `ComboBox`, or `Menu` for selection lists instead.

## Ask before building if:

- A long list of options is needed in the popover—clarify if this should be `Menu`, `ComboBox`, or a custom dropdown.
- The popover content is very tall—confirm if scrolling is needed or if content should be chunked into steps.
- The trigger is a button but popover content is menu-like—use `Menu` component instead for better semantics.

## Accessibility floor

- Trigger element must be keyboard-accessible (typically a `Button`).
- Escape key closes the popover.
- Click outside closes it.
- Content inside popover should be accessible (links, buttons, inputs all functional).

## Example

```tsx
import { Popover, Button, TextInput } from "@neeve/dls";
import { useState } from "react";

export function FilterButton() {
  const [open, setOpen] = useState(false);
  const [filterText, setFilterText] = useState("");

  return (
    <Popover open={open} onOpenChange={setOpen} side="bottom">
      <TextInput
        placeholder="Search..."
        value={filterText}
        onChange={(e) => setFilterText(e.target.value)}
      />
    </Popover>
  );
}
```
