# MultiSelect (DLS component)

**Layer:** `@neeve/dls` design system primitive

Select multiple options from a list. Displays selected items as removable chips.

## When to use

- Selecting multiple categories or tags
- Permission or scope multi-selection
- Bulk role assignment
- Any multi-choice form field

## Props

| Prop            | Type                                      | Required | Notes                           |
| --------------- | ----------------------------------------- | -------- | ------------------------------- |
| `value`         | `string[]`                                | Yes      | Currently selected values       |
| `onValueChange` | `(values: string[]) => void`              | Yes      | Callback when selection changes |
| `options`       | `Array<{ value: string; label: string }>` | Yes      | Available selections            |
| `placeholder`   | `string`                                  | No       | Placeholder text                |
| `disabled`      | `boolean`                                 | No       | Disables the field              |
| `label`         | `string`                                  | No       | Field label                     |

## Capabilities

- Handles multiple selection with checked state for each option.
- Displays selected items as removable chips below the field.
- Keyboard navigation (Arrow keys, Space to toggle, Tab) and click interactions.
- Integrates seamlessly with React Hook Form's `Controller` and Zod validation.

## Known limitations

- Does not support custom option rendering (icons, descriptions per option)—keep options simple.
- Does not virtualize lists—for very large lists (500+), performance may degrade.
- No search/filter within the dropdown—if searching is needed, use `ComboBox` (but it only does single-select).
- Removing chips requires clicking the X on each chip—there's no "Clear all" button built-in.

## Ask before building if:

- Searching within the options is needed ("user types to filter the list")—clarify if this should be `ComboBox` instead, or if `MultiSelect` + page-local filtering is acceptable.
- A "Clear all" button is needed—add page-local button that calls `onValueChange([])`, not a component feature.
- Very large option list (500+)—confirm if virtualization or server-side filtering is needed.
- Custom option rendering with icons/descriptions—ask designer if simple labels are sufficient.

## Accessibility floor

- `label` prop is strongly recommended—component auto-associates it via `htmlFor`.
- Keyboard navigation (Tab, Arrow keys, Space) is fully supported.
- Each chip has a remove button with accessible name.
- All selected/unselected states are announced.

## Example

```tsx
import { MultiSelect } from "@neeve/dls";
import { useState } from "react";

export function PermissionSelector() {
  const [permissions, setPermissions] = useState<string[]>([]);

  return (
    <MultiSelect
      label="Permissions"
      value={permissions}
      onValueChange={setPermissions}
      options={[
        { value: "read", label: "Read" },
        { value: "write", label: "Write" },
        { value: "delete", label: "Delete" },
        { value: "admin", label: "Admin" },
      ]}
      placeholder="Select permissions..."
    />
  );
}
```
