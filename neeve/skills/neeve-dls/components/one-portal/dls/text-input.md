# TextInput (DLS component)

**Layer:** `@neeve/dls` design system primitive

Single-line text field for user input. The workhorse input for forms, search bars, and filters.

## When to use

- Text form fields (name, email, hostname, IP address)
- Search inputs
- Numeric inputs (with `type="number"`)
- URL or path inputs
- Filtered search within lists

## Props

| Prop          | Type                                                   | Required | Notes                             |
| ------------- | ------------------------------------------------------ | -------- | --------------------------------- |
| `value`       | `string \| undefined`                                  | Yes      | Current input value               |
| `onChange`    | `(event: ChangeEvent<HTMLInputElement>) => void`       | Yes      | Fires on every keystroke          |
| `placeholder` | `string`                                               | No       | Placeholder text when empty       |
| `type`        | `"text" \| "email" \| "password" \| "number" \| "url"` | No       | HTML input type; default `"text"` |
| `label`       | `string`                                               | No       | Field label above input           |
| `error`       | `string`                                               | No       | Error message below field         |
| `disabled`    | `boolean`                                              | No       | Disables the field                |
| `required`    | `boolean`                                              | No       | Shows required indicator          |
| `className`   | `string`                                               | No       | Additional Tailwind classes       |

## Capabilities

- Handles focus ring, hover/disabled visual states, and validation error display natively.
- Supports all standard HTML5 input types (text, email, password, number, url, date, etc.) via `type` prop.
- Automatically associates label with input via `htmlFor` when `label` is provided.
- Integrates seamlessly with React Hook Form's `Controller` for validation and state management.

## Known limitations

- Not a search field with built-in clear button—use `SearchBar` component for that.
- Does not support autocomplete suggestions inline—use `ComboBox` for searchable/filtered lists.
- Does not handle multi-line input—use `TextArea` for that.
- No built-in character counter or character limit UI—use `maxLength` prop and display count in page-local code if needed.

## Ask before building if:

- The `type` prop isn't clear from context (is it email? number? password?). Always ask or infer from field name.
- A search/autocomplete behavior is implied ("user searches for a node")—clarify if this should be `TextInput` + filtering on the page, or `ComboBox`.
- Character limit or counter is needed—confirm whether one-portal design specifies a UI for this, or if it's validation-only.

## Accessibility floor

- `label` prop is strongly recommended for all inputs—the component auto-associates it via `htmlFor`, but label text must be provided.
- `error` text is announced to screen readers when present.
- `disabled` state is properly announced.
- `required` attribute is not automatically added—if the field is required, pass `required={true}` or use Zod validation that produces a clear error message.

## Examples

### Basic text input

```tsx
import { TextInput } from "@neeve/dls";
import { useState } from "react";

export function SearchEndpoints() {
  const [search, setSearch] = useState("");

  return (
    <TextInput
      label="Search by name"
      placeholder="e.g., 'Firewall-01'"
      value={search}
      onChange={(e) => setSearch(e.target.value)}
    />
  );
}
```

### With validation in a form

```tsx
import { TextInput, Button } from "@neeve/dls";
import { Controller, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

const schema = z.object({
  nodeName: z.string().min(1, "Node name is required").max(64),
  hostname: z.string().min(1, "Hostname is required"),
  ipAddress: z.string().ip("Invalid IP address"),
});

type FormData = z.infer<typeof schema>;

export function AddNodeForm() {
  const { control, handleSubmit } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  return (
    <form
      onSubmit={handleSubmit(onSubmit)}
      className="gap-dls-400 flex flex-col"
    >
      <Controller
        name="nodeName"
        control={control}
        render={({ field, fieldState: { error } }) => (
          <TextInput
            label="Node name"
            placeholder="My node"
            {...field}
            error={error?.message}
            required
          />
        )}
      />
      <Controller
        name="hostname"
        control={control}
        render={({ field, fieldState: { error } }) => (
          <TextInput
            label="Hostname"
            placeholder="node.example.com"
            {...field}
            error={error?.message}
            required
          />
        )}
      />
      <Controller
        name="ipAddress"
        control={control}
        render={({ field, fieldState: { error } }) => (
          <TextInput
            label="IP address"
            type="number"
            placeholder="192.168.1.1"
            {...field}
            error={error?.message}
            required
          />
        )}
      />
      <Button variant="primary" type="submit">
        Add node
      </Button>
    </form>
  );
}
```

### Used in one-portal: EnterNodeDetails.tsx

```tsx
<TextInput
  label="Node name"
  placeholder="Enter a name for this node"
  value={nodeName}
  onChange={(e) => setNodeName(e.target.value)}
  error={nodeNameError}
/>
```
