# Select (DLS component)

**Layer:** `@neeve/dls` design system primitive

Dropdown select field for choosing from a list of options. Use in forms, filters, and configuration panels.

## When to use

- Selecting from a predefined list (user role, system type, region)
- Filtering data (sort order, status filter)
- Configuration dropdowns
- Form fields with enumerated values

## Props

| Prop            | Type                                      | Required | Notes                              |
| --------------- | ----------------------------------------- | -------- | ---------------------------------- |
| `value`         | `string \| undefined`                     | Yes      | Currently selected value           |
| `onValueChange` | `(value: string) => void`                 | Yes      | Callback when selection changes    |
| `placeholder`   | `string`                                  | No       | Text shown when no option selected |
| `disabled`      | `boolean`                                 | No       | Disables the field                 |
| `options`       | `Array<{ value: string; label: string }>` | Yes      | Available selections               |
| `error`         | `string`                                  | No       | Error message below the field      |
| `label`         | `string`                                  | No       | Field label above                  |
| `className`     | `string`                                  | No       | Additional Tailwind classes        |

## Capabilities

- Handles open/close state, keyboard navigation (Arrow keys, Enter), and click interactions natively.
- Supports `placeholder` for "no selection" state.
- Integrates seamlessly with React Hook Form's `Controller` and Zod validation.
- Error messages display below the field when `error` prop is provided.
- Accessible via keyboard (Tab, Space/Enter, Arrow keys).

## Known limitations

- Does not support searching within options—use `ComboBox` for that.
- Does not support multi-select—use `MultiSelect` for that.
- Does not support custom option rendering (icons, descriptions per option)—if needed, use `ComboBox` or custom page-local dropdown.
- Option list is not virtualized—for very large lists (100+), performance may degrade; consider `ComboBox` instead.

## Ask before building if:

- The request implies searching within the list ("user filters the options")—clarify if this should be `Select`, or upgrade to `ComboBox`.
- Multi-select is needed ("user picks multiple roles")—use `MultiSelect` instead.
- Each option needs complex rendering (icon + label + description)—ask designer if `Select` is sufficient, or if a custom solution is needed.

## Accessibility floor

- `label` prop is strongly recommended—component auto-associates it via `htmlFor`.
- Keyboard navigation (Tab, Arrow keys, Space/Enter) is fully supported.
- Error text is announced to screen readers.
- `disabled` state is properly announced.

## Examples

### Basic select

```tsx
import { Select } from "@neeve/dls";
import { useState } from "react";

export function RoleSelector() {
  const [role, setRole] = useState("");

  return (
    <Select
      label="User role"
      value={role}
      onValueChange={setRole}
      placeholder="Select a role"
      options={[
        { value: "admin", label: "Administrator" },
        { value: "editor", label: "Editor" },
        { value: "viewer", label: "Viewer" },
      ]}
    />
  );
}
```

### Select with validation error

```tsx
import { Select, Button } from "@neeve/dls";
import { Controller, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

const schema = z.object({
  systemType: z.string().min(1, "System type is required"),
});

export function SystemTypeForm() {
  const { control, handleSubmit } = useForm({
    resolver: zodResolver(schema),
  });

  return (
    <form
      onSubmit={handleSubmit(onSubmit)}
      className="gap-dls-400 flex flex-col"
    >
      <Controller
        name="systemType"
        control={control}
        render={({ field, fieldState: { error } }) => (
          <Select
            label="System type"
            {...field}
            placeholder="Choose a type"
            options={[
              { value: "router", label: "Router" },
              { value: "firewall", label: "Firewall" },
              { value: "switch", label: "Switch" },
            ]}
            error={error?.message}
          />
        )}
      />
      <Button variant="primary" type="submit">
        Save
      </Button>
    </form>
  );
}
```

### Used in one-portal: ConnectionsFilterDialog.tsx

```tsx
<Select
  label="System type"
  value={selectedType}
  onValueChange={setSelectedType}
  options={systemTypes.map((t) => ({
    value: t.id,
    label: t.name,
  }))}
/>
```

## Capabilities

- Handles open/close state, keyboard navigation (Arrow keys, Enter), and click interactions natively.
- Supports `placeholder` for "no selection" state.
- Integrates seamlessly with React Hook Form's `Controller` and Zod validation.
- Error messages display below the field when `error` prop is provided.
- Accessible via keyboard (Tab, Space/Enter, Arrow keys).

## Known limitations

- Does not support searching within options—use `ComboBox` for that.
- Does not support multi-select—use `MultiSelect` for that.
- Does not support custom option rendering (icons, descriptions per option)—if needed, use `ComboBox` or custom page-local dropdown.
- Option list is not virtualized—for very large lists (100+), performance may degrade; consider `ComboBox` instead.

## Ask before building if:

- The request implies searching within the list ("user filters the options")—clarify if this should be `Select`, or upgrade to `ComboBox`.
- Multi-select is needed ("user picks multiple roles")—use `MultiSelect` instead.
- Each option needs complex rendering (icon + label + description)—ask designer if `Select` is sufficient, or if a custom solution is needed.

## Accessibility floor

- `label` prop is strongly recommended—component auto-associates it via `htmlFor`.
- Keyboard navigation (Tab, Arrow keys, Space/Enter) is fully supported.
- Error text is announced to screen readers.
- `disabled` state is properly announced.

## Examples
