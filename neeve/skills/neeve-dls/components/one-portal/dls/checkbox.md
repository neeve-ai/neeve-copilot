# Checkbox (DLS component)

**Layer:** `@neeve/dls` design system primitive

Binary toggle control for selecting items or confirming options. Used in forms, lists, and bulk actions.

## When to use

- Row selection in tables
- Multiple-choice form fields
- Feature toggles or options lists
- Bulk action selections
- Terms/conditions acceptance

## Props

| Prop              | Type                         | Required | Notes                                         |
| ----------------- | ---------------------------- | -------- | --------------------------------------------- |
| `checked`         | `boolean`                    | Yes      | Current checked state                         |
| `onCheckedChange` | `(checked: boolean) => void` | Yes      | Callback when toggled                         |
| `label`           | `string \| ReactNode`        | No       | Text label next to checkbox                   |
| `disabled`        | `boolean`                    | No       | Disables interaction                          |
| `indeterminate`   | `boolean`                    | No       | Shows indeterminate state (partial selection) |
| `className`       | `string`                     | No       | Additional Tailwind classes                   |
| `id`              | `string`                     | No       | HTML id for accessibility                     |

## Capabilities

- Handles checked, unchecked, and indeterminate states natively.
- Supports keyboard navigation (Space to toggle) and click interactions.
- Indeterminate state is useful for "select all" workflows or parent/child checkbox groups.
- Integrates seamlessly with React Hook Form's `Controller` and Zod validation.
- Accessible name is provided via `label` prop; component auto-associates via `htmlFor`.

## Known limitations

- Does not automatically manage parent/child checkbox logic—page-local code must handle "select all" or grouped checkbox state.
- Not a form of multi-select dropdown—use `MultiSelect` component for searchable/scrollable option lists.
- Indeterminate state is visual only—it does not automatically compute from child checkboxes; you must set it explicitly.

## Ask before building if:

- The request implies "select all" or nested checkbox groups—clarify whether this should be a single checkbox, or a group with parent/child logic.
- A list of many checkboxes is needed (e.g., "pick 50 tags")—consider `MultiSelect` instead for scrollable, searchable UX.
- A checkbox is needed in a table with bulk selection—confirm this pairs with `BulkActionBar` for the action bar state management.

## Accessibility floor

- `label` prop is required for all checkboxes—component auto-associates it via `htmlFor`.
- Keyboard navigation (Space, Tab) is provided.
- Indeterminate state visual is present and announced.
- `disabled` state is properly announced to screen readers.

## Examples

### Simple checkbox with label

```tsx
import { Checkbox } from "@neeve/dls";
import { useState } from "react";

export function AgreementCheckbox() {
  const [agreed, setAgreed] = useState(false);

  return (
    <Checkbox
      checked={agreed}
      onCheckedChange={setAgreed}
      label="I agree to the terms and conditions"
      id="terms-agreement"
    />
  );
}
```

### Checkbox list for multi-select

```tsx
import { Checkbox } from "@neeve/dls";
import { useState } from "react";

export function PermissionSelector() {
  const [permissions, setPermissions] = useState<Record<string, boolean>>({
    read: false,
    write: false,
    delete: false,
  });

  const togglePermission = (perm: string) => {
    setPermissions((prev) => ({
      ...prev,
      [perm]: !prev[perm],
    }));
  };

  return (
    <div className="gap-dls-200 flex flex-col">
      <Checkbox
        checked={permissions.read}
        onCheckedChange={() => togglePermission("read")}
        label="Read"
      />
      <Checkbox
        checked={permissions.write}
        onCheckedChange={() => togglePermission("write")}
        label="Write"
      />
      <Checkbox
        checked={permissions.delete}
        onCheckedChange={() => togglePermission("delete")}
        label="Delete"
      />
    </div>
  );
}
```

### Used in one-portal: ObjectScopeSelection.tsx

```tsx
<Checkbox
  checked={scope.selected}
  onCheckedChange={(checked) => updateScope(scope.id, checked)}
  label={scope.name}
/>
```
