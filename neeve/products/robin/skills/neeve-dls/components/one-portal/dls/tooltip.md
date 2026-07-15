# Tooltip (DLS component)

**Layer:** `@neeve/dls` design system primitive

Hover-triggered popup with helpful context. Use for abbreviations, icons, and brief explanations.

## When to use

- Icon explanations (what does this icon mean?)
- Abbreviation expansions (TCP → Transmission Control Protocol)
- Keyboard shortcut hints
- Additional context for form fields
- Truncated text expansion

## Props

| Prop        | Type                                     | Required | Notes                             |
| ----------- | ---------------------------------------- | -------- | --------------------------------- |
| `content`   | `string \| ReactNode`                    | Yes      | Tooltip text/content              |
| `children`  | `ReactNode`                              | Yes      | Element that triggers tooltip     |
| `side`      | `"top" \| "right" \| "bottom" \| "left"` | No       | Tooltip position; default `"top"` |
| `delayMs`   | `number`                                 | No       | Delay before showing (ms)         |
| `className` | `string`                                 | No       | Additional Tailwind classes       |

## Capabilities

- Hover-triggered popup with auto-positioning around trigger element.
- Supports four directional placements (top, right, bottom, left).
- Optional delay before showing (default immediate).
- Content supports both plain text and React nodes (e.g., code snippets, formatted text).

## Known limitations

- Not keyboard-triggered—tooltip only shows on hover or focus (platform-dependent).
- No dismiss on Escape (some implementations may not support)—user must move away from trigger.
- Cannot be positioned absolutely; uses floating-ui for auto-positioning.
- Content is not selectable (some tooltip implementations prevent text selection).

## Ask before building if:

- Tooltip should be keyboard-accessible (Shift+Tab to show hint)—use explicit hint/help text instead, or confirm keyboard trigger with designer.
- Very long tooltip content is needed—consider a help panel or `Dialog` instead; tooltips are for brief hints only.
- Tooltip should remain visible on click—use `Dialog` or `Popover` instead.

## Accessibility floor

- Trigger element must be keyboard-accessible (button, link, or input).
- Tooltip content is announced on hover/focus via `role="tooltip"` and `aria-describedby`.
- `delayMs` respects user preferences (no flash/distraction).

## Example

```tsx
import { Tooltip, Button } from "@neeve/dls";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faQuestion } from "@view/pro-regular-svg-icons";

export function FormFieldWithHelp() {
  return (
    <div className="gap-dls-200 flex items-center">
      <label>Network CIDR</label>
      <Tooltip content="Classless Inter-Domain Routing notation (e.g., 192.168.1.0/24)">
        <FontAwesomeIcon
          icon={faQuestion}
          className="text-foreground-secondary cursor-help"
        />
      </Tooltip>
    </div>
  );
}
```
