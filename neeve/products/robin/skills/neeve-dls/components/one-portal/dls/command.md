# Command (DLS component)

**Layer:** `@neeve/dls` design system primitive

Command palette UI for keyboard-driven command execution. Typically opened with Cmd+K.

## When to use

- Command palettes for power users
- Keyboard-driven navigation and actions
- Quick action search (Cmd+K to search)
- Global search experiences

## Props

| Prop           | Type                      | Required | Notes                    |
| -------------- | ------------------------- | -------- | ------------------------ |
| `open`         | `boolean`                 | Yes      | Palette open/closed      |
| `onOpenChange` | `(open: boolean) => void` | Yes      | State callback           |
| `placeholder`  | `string`                  | No       | Search input placeholder |
| `groups`       | `CommandGroup[]`          | Yes      | Grouped commands         |

## Capabilities

- Searchable command palette with keyboard-driven interaction (Arrow keys, Enter, Escape).
- Supports grouped commands for organization (e.g., "Navigation", "Actions").
- Fuzzy search filtering across commands.
- Modal/dialog overlay pattern.

## Known limitations

- No built-in Cmd+K (or Ctrl+K) handler—page-local code must wire up keyboard shortcut.
- Does not auto-navigate or execute commands—each command must have an `onSelect` callback with page-local logic.
- Search is fuzzy only—no exact match filters or advanced query syntax.

## Ask before building if:

- Keyboard shortcut (Cmd+K) should auto-open palette—add page-local `useEffect` + `useKeyPress` hook.
- Commands need to execute without user selection (auto-execute on search match)—clarify this is power-user UX intended.
- Command groups need to be collapsible—not supported; confirm flat structure is acceptable.

## Accessibility floor

- Command palette is a modal with focus management.
- Search input is focused on open.
- Keyboard navigation (Arrow keys, Enter, Escape) fully supported.
- Commands are announced with their group (e.g., "Navigation: Go to Nodes").

## Example

```tsx
import {
  CommandDialog,
  CommandInput,
  CommandList,
  CommandItem,
} from "@neeve/dls";
import { useState } from "react";
import { useRouter } from "next/navigation";

export function CommandPalette() {
  const [open, setOpen] = useState(false);
  const router = useRouter();

  return (
    <CommandDialog open={open} onOpenChange={setOpen}>
      <CommandInput placeholder="Search endpoints, nodes, users..." />
      <CommandList>
        <CommandItem onClick={() => router.push("/manage/endpoints")}>
          Go to endpoints
        </CommandItem>
        <CommandItem onClick={() => router.push("/manage/nodes")}>
          Go to nodes
        </CommandItem>
      </CommandList>
    </CommandDialog>
  );
}
```
