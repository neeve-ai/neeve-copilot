# PromptBar (DLS component)

**Layer:** `@neeve/dls` design system primitive

AI-powered prompt input bar. Use for conversational interfaces or AI assistance inputs.

## When to use

- Chat interfaces
- AI assistant input
- Prompt/command input
- Conversational UI

## Props

| Prop          | Type                      | Required | Notes                                       |
| ------------- | ------------------------- | -------- | ------------------------------------------- |
| `value`       | `string`                  | Yes      | Current input value                         |
| `onChange`    | `(value: string) => void` | Yes      | Input change callback                       |
| `onSubmit`    | `() => void`              | Yes      | Submit callback (Cmd+Enter or button click) |
| `placeholder` | `string`                  | No       | Input placeholder                           |
| `isLoading`   | `boolean`                 | No       | Shows loading state                         |
| `disabled`    | `boolean`                 | No       | Disables input                              |

## Capabilities

- Text input with submit button (or Cmd+Enter shortcut).
- Supports loading state (button disabled, spinner).
- Optional placeholder and disabled states.

## Known limitations

- No rich text or markdown support—plain text only.
- Does not auto-focus on mount—page-local code must manage focus for accessibility.
- No debouncing or character limits built-in.

## Ask before building if:

- Rich text formatting is needed—use custom editor component, not `PromptBar`.
- Auto-focus on page load is expected—add `useEffect` + `useRef` for focus management.
- Character limit or input validation needed—add page-local validation logic.

## Accessibility floor

- Input field should have visible label or `aria-label` ("Chat message", "Ask question", etc.).
- Submit button is keyboard-accessible (Tab, Enter).
- Loading state is announced (e.g., `aria-busy="true"`).
- Cmd+Enter is standard for submit; document this for users.

## Example

```tsx
import { PromptBar } from "@neeve/dls";
import { useState } from "react";

export function AIChat() {
  const [prompt, setPrompt] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async () => {
    setIsLoading(true);
    try {
      await sendPrompt(prompt);
      setPrompt("");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <PromptBar
      value={prompt}
      onChange={setPrompt}
      onSubmit={handleSubmit}
      placeholder="Ask me anything about your infrastructure..."
      isLoading={isLoading}
    />
  );
}
```
