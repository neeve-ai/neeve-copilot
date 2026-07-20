# Menubar (DLS component)

**Layer:** `@neeve/dls` design system primitive

Application-level menu bar with multiple menus. Typically used in page headers for organizing actions and views.

## When to use

- Page-level toolbar with multiple action groups
- Export, view, and settings menus in one place
- Application menu bar (File, Edit, View, Help)
- Organizing many actions into logical groups

## Props / Subcomponents

- `Menubar` — container
- `MenubarMenu` — menu group
- `MenubarTrigger` — menu label/button
- `MenubarContent` — dropdown options
- `MenubarItem` — individual action

## Example

```tsx
import {
  Menubar,
  MenubarMenu,
  MenubarTrigger,
  MenubarContent,
  MenubarItem,
  MenubarSeparator,
} from "@neeve/dls";
import { Button } from "@neeve/dls";

export function TableToolbar() {
  return (
    <Menubar>
      <MenubarMenu>
        <MenubarTrigger>View</MenubarTrigger>
        <MenubarContent>
          <MenubarItem onClick={() => toggleDenseMode()}>
            Dense mode
          </MenubarItem>
          <MenubarItem onClick={() => toggleColumns()}>Columns...</MenubarItem>
        </MenubarContent>
      </MenubarMenu>

      <MenubarMenu>
        <MenubarTrigger>Export</MenubarTrigger>
        <MenubarContent>
          <MenubarItem onClick={() => exportCSV()}>CSV</MenubarItem>
          <MenubarItem onClick={() => exportJSON()}>JSON</MenubarItem>
        </MenubarContent>
      </MenubarMenu>
    </Menubar>
  );
}
```

## Capabilities

- Organizes multiple menus in a horizontal bar.
- Keyboard navigation (Tab between menus, Arrow keys within menu, Enter to select).
- Auto-close and auto-open on hover for rapid menu access.

## Known limitations

- Does not support nested submenus—menus are flat (Menu > Items only).
- No keyboard shortcut binding—shortcuts are display-only; page-local code wires them up.
- Limited to horizontal layout; vertical stacking not supported.

## Ask before building if:

- Nested menus are needed—clarify if flat menu structure is acceptable.
- Many menus (10+) will appear—confirm this is the right UX, or if collapsing/dropdowns are needed.
- Keyboard shortcuts should auto-trigger—add page-local event listeners.

## Accessibility floor

- Menu labels are announced.
- Keyboard navigation (Tab, Arrow keys, Enter) is fully supported.
- Semantic menu structure is preserved (screen readers announce "menu bar", "menu", "menu item").

## Example

### Used in one-portal: ListUsers.tsx

```tsx
<Menubar>
  <MenubarMenu>
    <MenubarTrigger>View</MenubarTrigger>
    <MenubarContent>{/* menu items */}</MenubarContent>
  </MenubarMenu>
</Menubar>
```
