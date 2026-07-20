# TextArea (DLS component)

**Layer:** `@neeve/dls` design system primitive

Multi-line text input for longer content. Use for comments, descriptions, and detailed text entry.

## When to use

- Long-form text input (descriptions, notes, configurations)
- Comments or feedback fields
- Large text areas where line breaks matter
- Anything requiring more than one line of entry

## Props

| Prop          | Type                                                | Required | Notes                             |
| ------------- | --------------------------------------------------- | -------- | --------------------------------- |
| `value`       | `string \| undefined`                               | Yes      | Current input value               |
| `onChange`    | `(event: ChangeEvent<HTMLTextAreaElement>) => void` | Yes      | Fires on every keystroke          |
| `placeholder` | `string`                                            | No       | Placeholder text when empty       |
| `label`       | `string`                                            | No       | Field label above textarea        |
| `error`       | `string`                                            | No       | Error message below field         |
| `disabled`    | `boolean`                                           | No       | Disables the field                |
| `rows`        | `number`                                            | No       | Number of visible rows; default 4 |
| `maxLength`   | `number`                                            | No       | Maximum characters allowed        |
| `className`   | `string`                                            | No       | Additional Tailwind classes       |

## Capabilities

- Handles focus ring, hover/disabled visual states, and validation error display natively.
- Auto-expands vertically as user types (via CSS `resize: none; overflow-y: auto`).
- Integrates seamlessly with React Hook Form's `Controller` for validation and state management.
- Automatically associates label with textarea via `htmlFor` when `label` is provided.

## Known limitations

- Does not auto-grow to fit content on first render—it has a fixed `rows` height initially.
- No built-in character counter or character limit UI—use `maxLength` prop; if a visible counter is needed, add it in page-local code.
- Not suitable for code editing or syntax highlighting—use a third-party code editor component for that.
- Does not support rich text (bold, italic, etc.)—use a rich text editor package if needed.

## Ask before building if:

- A character limit or counter UI is needed—confirm whether one-portal design specifies how to display this.
- The textarea needs to auto-expand on first render to fit initial content—this requires page-local JS, not a component feature.
- Rich text editing is implied ("user formats their message")—this exceeds `TextArea` scope; clarify if it should be markdown, HTML, or plain text only.

## Accessibility floor

- `label` prop is strongly recommended for all textareas—the component auto-associates it via `htmlFor`.
- `error` text is announced to screen readers when present.
- `disabled` state is properly announced.
- `required` attribute is not automatically added—use Zod validation for clear error messages.

## Example

```tsx
import { TextArea, Button } from "@neeve/dls";
import { useState } from "react";

export function NodeDescriptionForm() {
  const [description, setDescription] = useState("");
  const [charCount, setCharCount] = useState(0);

  const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setDescription(e.target.value);
    setCharCount(e.target.value.length);
  };

  return (
    <form className="gap-dls-400 flex flex-col">
      <TextArea
        label="Node description"
        placeholder="Describe this node's purpose and location..."
        value={description}
        onChange={handleChange}
        rows={6}
        maxLength={500}
      />
      <div className="text-foreground-secondary text-sm">
        {charCount} / 500 characters
      </div>
      <Button variant="primary" type="submit">
        Save
      </Button>
    </form>
  );
}
```
