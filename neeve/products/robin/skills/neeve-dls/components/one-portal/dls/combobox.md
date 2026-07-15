# ComboBox (DLS component)

**Layer:** `@neeve/dls` design system primitive

Searchable select dropdown. Combines a text input with a filtered option list. Use for large lists where typing helps find options.

## When to use

- Selecting from large option lists (100+ items)
- Autocomplete/filtered searches
- City, region, or country selectors
- Any select field where users need to filter options

## Props

| Prop                | Type                                      | Required | Notes                           |
| ------------------- | ----------------------------------------- | -------- | ------------------------------- |
| `value`             | `string \| undefined`                     | Yes      | Currently selected value        |
| `onValueChange`     | `(value: string) => void`                 | Yes      | Callback when selection changes |
| `options`           | `Array<{ value: string; label: string }>` | Yes      | Available selections            |
| `placeholder`       | `string`                                  | No       | Placeholder when closed         |
| `searchPlaceholder` | `string`                                  | No       | Placeholder in search input     |
| `notFoundText`      | `string`                                  | No       | Message when no matches         |
| `disabled`          | `boolean`                                 | No       | Disables the field              |
| `label`             | `string`                                  | No       | Field label above               |
| `error`             | `string`                                  | No       | Error message below             |

## Capabilities

- Handles filtering/searching options as user types.
- Keyboard navigation (Arrow keys, Enter, Escape) and click interactions natively.
- Displays "no matches" state when search yields no results.
- Integrates seamlessly with React Hook Form's `Controller` and Zod validation.

## Known limitations

- Does not support multi-select—use `MultiSelect` for that.
- Does not virtualize lists—for 1000+ options, performance may degrade.
- Search is simple substring match—fuzzy matching or complex filters require custom page-local logic.
- Does not support custom option rendering (icons, descriptions)—keep options simple or build a custom wrapper.

## Ask before building if:

- Multi-select is needed ("user picks multiple cities")—use `MultiSelect` instead.
- Fuzzy or advanced search is needed ("typo-tolerant matching")—clarify if simple substring is sufficient, or if custom filtering is needed.
- Very large option list (1000+)—confirm if virtualization or server-side filtering is needed.
- Custom option rendering with icons/descriptions—ask designer if `ComboBox` simple label is sufficient.

## Accessibility floor

- `label` prop is strongly recommended—component auto-associates it via `htmlFor`.
- Keyboard navigation (Tab, Arrow keys, Enter) is fully supported.
- Search input and results list are semantically linked.
- Error text is announced to screen readers.

## Example

```tsx
import { ComboBox } from "@neeve/dls";
import { useState } from "react";

export function SystemTypeSelector({ value, onChange }: Props) {
  const systemTypes = [
    { value: "router", label: "Cisco Router" },
    { value: "firewall", label: "Palo Alto Firewall" },
    { value: "switch", label: "Arista Switch" },
    { value: "loadbalancer", label: "F5 Load Balancer" },
    // ... 100+ more
  ];

  return (
    <ComboBox
      label="System type"
      value={value}
      onValueChange={onChange}
      options={systemTypes}
      placeholder="Search system types..."
      searchPlaceholder="Type to filter..."
    />
  );
}
```
