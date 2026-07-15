# Menu (DLS component)

**Layer:** `@neeve/dls` design system primitive

Context menu for actions. Use for dropdown menus triggered by click on an element.

## When to use

- Row action menus ("Edit", "Delete", "Copy")
- Context menus (right-click inspired)
- Dropdown action lists
- Icon button menus ("⋮" three-dot menu)

## Props (depends on implementation)

Menu typically has subcomponents:

- `MenuTrigger` — element that opens menu
- `MenuContent` — dropdown container
- `MenuItem` — individual option
- `MenuSeparator` — divider line

## Capabilities

- Handles click-to-open, keyboard navigation (Arrow keys, Enter, Escape), and click-outside-to-close.
- Supports keyboard shortcuts or hints (display-only, not enforced by component).
- Each `MenuItem` can have an `onClick` handler.

## Known limitations

- Does not support nested submenus—if nested menus are needed, build custom solution or use Radix submenus directly.
- No built-in keyboard shortcut handling—shortcuts are display-only; page-local code must wire them up.
- Icon support depends on wrapper (pass JSX to `MenuItem` children for custom rendering).

## Ask before building if:

- Nested submenus are needed ("Edit > Delete…")—clarify if this is UX best practice, or if flat menu with confirmation dialogs is better.
- Keyboard shortcuts should trigger menu items—add page-local shortcut listeners, not a component feature.
- Menu items have complex content (icons + labels + hints)—confirm layout with designer or use custom `MenuItem` children.

## Accessibility floor

- Trigger element must be keyboard-accessible (typically a `Button`).
- Keyboard navigation (Tab, Arrow keys, Enter, Escape) is fully supported.
- Menu label and item text are announced.

## Example

```tsx
import { Menu, MenuTrigger, MenuContent, MenuItem } from "@neeve/dls";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faEllipsis } from "@view/pro-solid-svg-icons";

export function EndpointRowActions({ endpoint }: Props) {
  return (
    <Menu>
      <MenuTrigger>
        <button>
          <FontAwesomeIcon icon={faEllipsis} />
        </button>
      </MenuTrigger>
      <MenuContent>
        <MenuItem onClick={() => handleEdit(endpoint)}>Edit</MenuItem>
        <MenuItem onClick={() => handleDuplicate(endpoint)}>Duplicate</MenuItem>
        <MenuItem
          onClick={() => handleDelete(endpoint)}
          className="text-error-primary"
        >
          Delete
        </MenuItem>
      </MenuContent>
    </Menu>
  );
}
```
