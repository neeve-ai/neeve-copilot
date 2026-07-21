# Accordion (Standalone component)

**Layer:** Wrapper component (`standalones/components`) — builds on Radix UI with one-portal theming and DLS styling

Expandable/collapsible item container for grouping related content. Supports single or multiple items open simultaneously.

## When to use

- Grouped content that should be collapsed by default (reduce visual clutter)
- FAQs or help sections
- Settings panels with multiple categories
- Step-by-step wizards or multi-section forms

## Props

| Component          | Prop            | Type                                       | Required | Notes                                        |
| ------------------ | --------------- | ------------------------------------------ | -------- | -------------------------------------------- |
| `Accordion`        | `type`          | `"single" \| "multiple"`                   | Yes      | Single or multiple items can be open         |
|                    | `value`         | `string` (single) or `string[]` (multiple) | No       | Controlled open state                        |
|                    | `onValueChange` | `(value: string \| string[]) => void`      | No       | Callback when state changes                  |
|                    | `collapsible`   | `boolean`                                  | No       | Allow closing opened item (single mode only) |
|                    | `className`     | `string`                                   | No       | Additional Tailwind classes                  |
| `AccordionItem`    | `value`         | `string`                                   | Yes      | Unique identifier for this item              |
|                    | `className`     | `string`                                   | No       | Additional Tailwind classes                  |
| `AccordionTrigger` | `children`      | `ReactNode`                                | Yes      | Header/trigger label text                    |
|                    | `level`         | `number`                                   | No       | Nesting depth for padding (`dls-pl-${n*8}`)  |
|                    | `className`     | `string`                                   | No       | Additional Tailwind classes                  |
| `AccordionContent` | `children`      | `ReactNode`                                | Yes      | Body content (expanded state)                |
|                    | `className`     | `string`                                   | No       | Additional Tailwind classes                  |

## Capabilities

- Built on Radix UI Accordion with one-portal DLS theming applied.
- Single mode: Only one item open at a time; previous item auto-closes.
- Multiple mode: Multiple items can be open; `collapsible` allows manually closing items.
- Animated open/close transitions with chevron icon rotation.
- Keyboard navigation: Arrow keys, Enter to expand, Space to toggle.
- Nested items support via `level` prop for visual indentation.
- Controlled and uncontrolled modes via `value` and `onValueChange`.

## Known limitations

- No lazy-loading of content—expanded content is rendered immediately (not on-demand).
- Nested accordion support requires manual nesting of components; no auto-expansion of parent items.
- All items render in DOM regardless of open state (content is hidden, not removed).

## Ask before building if:

- Lazy-loading of item content is needed for performance (100+ items)—consider pagination or virtualization instead.
- Deeply nested accordion (5+ levels) is needed—confirm UX is appropriate; consider alternate navigation pattern.
- Custom expand/collapse animations are needed—use `AccordionContent` className prop for CSS overrides.

## Accessibility floor

- Accordion is semantic (`role="tablist"`).
- Each trigger is a `<button>` with `aria-expanded` and `aria-controls`.
- Keyboard navigation (Arrow keys, Enter, Space) fully supported.
- Chevron icon animates to indicate state.
- Content is announced when item expands.

## Examples

### Simple single-item accordion

```tsx
import {
  Accordion,
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
} from "@/standalones/components";

export function FAQSection() {
  return (
    <Accordion type="single" collapsible>
      <AccordionItem value="item-1">
        <AccordionTrigger>How do I create an endpoint?</AccordionTrigger>
        <AccordionContent>
          Click "Add Endpoint" in the toolbar, fill in the required fields, and
          click save.
        </AccordionContent>
      </AccordionItem>

      <AccordionItem value="item-2">
        <AccordionTrigger>
          Can I edit an endpoint after creation?
        </AccordionTrigger>
        <AccordionContent>
          Yes, click the endpoint row and select "Edit" from the actions menu.
          Changes take effect immediately.
        </AccordionContent>
      </AccordionItem>
    </Accordion>
  );
}
```

### Controlled accordion with multiple items open

```tsx
import { useState } from "react";
import {
  Accordion,
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
} from "@/standalones/components";

export function SettingsPanel() {
  const [openSections, setOpenSections] = useState<string[]>(["general"]);

  return (
    <Accordion
      type="multiple"
      value={openSections}
      onValueChange={setOpenSections}
    >
      <AccordionItem value="general">
        <AccordionTrigger>General Settings</AccordionTrigger>
        <AccordionContent>
          <div className="gap-dls-300 flex flex-col">
            <label>Organization Name</label>
            <input type="text" placeholder="Your org" />
          </div>
        </AccordionContent>
      </AccordionItem>

      <AccordionItem value="security">
        <AccordionTrigger>Security</AccordionTrigger>
        <AccordionContent>
          <div className="gap-dls-300 flex flex-col">
            <label>Two-Factor Authentication</label>
            <toggle />
          </div>
        </AccordionContent>
      </AccordionItem>
    </Accordion>
  );
}
```

### Nested hierarchy with level indentation

```tsx
import {
  Accordion,
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
} from "@/standalones/components";

export function HierarchyAccordion() {
  const [openItems, setOpenItems] = useState<string[]>([]);

  return (
    <Accordion type="multiple" value={openItems} onValueChange={setOpenItems}>
      {/* Level 0 */}
      <AccordionItem value="org">
        <AccordionTrigger level={0}>Organization</AccordionTrigger>
        <AccordionContent>
          {/* Nested Level 1 */}
          <Accordion type="multiple">
            <AccordionItem value="portfolio-1">
              <AccordionTrigger level={1}>Portfolio A</AccordionTrigger>
              <AccordionContent>
                {/* Level 2 content */}
                Site A1, Site A2
              </AccordionContent>
            </AccordionItem>

            <AccordionItem value="portfolio-2">
              <AccordionTrigger level={1}>Portfolio B</AccordionTrigger>
              <AccordionContent>Site B1</AccordionContent>
            </AccordionItem>
          </Accordion>
        </AccordionContent>
      </AccordionItem>
    </Accordion>
  );
}
```
