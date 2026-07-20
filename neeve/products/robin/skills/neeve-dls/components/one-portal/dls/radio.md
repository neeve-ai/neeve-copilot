# Radio (DLS component)

**Layer:** `@neeve/dls` design system primitive

Mutually exclusive option selector. Use when only one choice from a group is valid.

## When to use

- Single-choice form options (payment method, connection type)
- Mode selection (desktop view vs. mobile view)
- Yes/No questions
- Priority or status selection
- Configuration options where only one applies

**Difference from Checkbox:** Radio buttons enforce one selection per group; checkboxes allow multiple.

## Props

| Prop              | Type                         | Required | Notes                                      |
| ----------------- | ---------------------------- | -------- | ------------------------------------------ |
| `checked`         | `boolean`                    | Yes      | Current selected state                     |
| `onCheckedChange` | `(checked: boolean) => void` | Yes      | Callback when selected                     |
| `label`           | `string \| ReactNode`        | No       | Text label next to radio                   |
| `disabled`        | `boolean`                    | No       | Disables interaction                       |
| `id`              | `string`                     | No       | HTML id for accessibility                  |
| `name`            | `string`                     | No       | Group name (standard HTML radio semantics) |
| `value`           | `string`                     | No       | Option value (standard HTML)               |
| `className`       | `string`                     | No       | Additional Tailwind classes                |

## Capabilities

- Handles mutually exclusive selection (only one radio in a group can be checked at a time).
- Keyboard navigation (Tab to focus, Arrow keys to switch within group, Space to select) is built-in.
- Integrates seamlessly with React Hook Form's `Controller` and Zod validation.
- Supports `disabled` state for individual radio buttons.
- Accessible name is provided via `label` prop; component auto-associates via `htmlFor`.

## Known limitations

- Does not automatically manage radio group state—page-local code or React Hook Form must handle the `name` grouping and `checked` state.
- Not a select dropdown—use `Select` or `ComboBox` for longer option lists.
- No built-in "none selected" state—if you need "unselect" behavior, use a `Checkbox` or add a separate "Clear" button.
- Radio buttons should be visually grouped; the component itself does not provide layout—use page-local `<fieldset>` + `<legend>` for proper semantics.

## Ask before building if:

- The request implies "select one of many" but doesn't say how many options—if there are 5+, suggest `Select` or `ComboBox` instead.
- An "unselect" option is needed (user can go back to no selection)—clarify if this should be a separate button, or a "None" radio option.
- Options are complex (icons, descriptions)—confirm layout via designer or example, or use `RadioGroup` subcomponent if one-portal provides it.

## Accessibility floor

- `label` prop is required for all radio buttons—component auto-associates via `htmlFor`.
- `name` prop groups radios semantically (screen readers announce them as a group).
- Keyboard navigation (Tab, Arrow keys, Space) is provided.
- `disabled` state is properly announced.
- Use `<fieldset>` + `<legend>` around a radio group for semantic grouping (page-local markup).

## Examples

### Single radio group

```tsx
import { Radio } from "@neeve/dls";
import { useState } from "react";

export function ConnectionTypeSelector() {
  const [type, setType] = useState("direct");

  return (
    <div className="gap-dls-200 flex flex-col">
      <Radio
        checked={type === "direct"}
        onCheckedChange={() => setType("direct")}
        label="Direct connection"
        name="connection-type"
        value="direct"
      />
      <Radio
        checked={type === "tunnel"}
        onCheckedChange={() => setType("tunnel")}
        label="Via tunnel"
        name="connection-type"
        value="tunnel"
      />
      <Radio
        checked={type === "proxy"}
        onCheckedChange={() => setType("proxy")}
        label="Through proxy"
        name="connection-type"
        value="proxy"
      />
    </div>
  );
}
```

### With descriptions

```tsx
import { Radio } from "@neeve/dls";
import { useState } from "react";

export function AccessLevelSelector() {
  const [level, setLevel] = useState("viewer");

  return (
    <div className="gap-dls-300 flex flex-col">
      <div>
        <Radio
          checked={level === "admin"}
          onCheckedChange={() => setLevel("admin")}
          label="Administrator"
          name="access-level"
          value="admin"
        />
        <p className="text-foreground-secondary ml-dls-600 text-sm">
          Full access to all resources and settings
        </p>
      </div>
      <div>
        <Radio
          checked={level === "editor"}
          onCheckedChange={() => setLevel("editor")}
          label="Editor"
          name="access-level"
          value="editor"
        />
        <p className="text-foreground-secondary ml-dls-600 text-sm">
          Can create and edit resources
        </p>
      </div>
      <div>
        <Radio
          checked={level === "viewer"}
          onCheckedChange={() => setLevel("viewer")}
          label="Viewer"
          name="access-level"
          value="viewer"
        />
        <p className="text-foreground-secondary ml-dls-600 text-sm">
          Read-only access
        </p>
      </div>
    </div>
  );
}
```

### Used in one-portal: CollectIPFromUser.tsx

```tsx
<Radio
  checked={method === "manual"}
  onCheckedChange={() => setMethod("manual")}
  label="Enter IP address manually"
  name="ip-method"
  value="manual"
/>
```
