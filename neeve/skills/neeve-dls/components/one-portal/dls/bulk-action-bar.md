# BulkActionBar (DLS component)

**Layer:** `@neeve/dls` design system primitive

Floating action bar that appears when items are selected. Use with tables and lists that support multi-select.

## When to use

- Table row bulk selection actions
- Bulk delete/export from lists
- Multi-item operations
- Context actions that appear when items are selected

## Props

| Prop            | Type                | Required | Notes                            |
| --------------- | ------------------- | -------- | -------------------------------- |
| `selectedCount` | `number`            | Yes      | Number of selected items         |
| `actions`       | `ReactNode`         | Yes      | Action buttons to display        |
| `onClear`       | `() => void`        | Yes      | Callback to clear selection      |
| `position`      | `"top" \| "bottom"` | No       | Bar position; default `"bottom"` |
| `className`     | `string`            | No       | Additional Tailwind classes      |

## Capabilities

- Floating bar that appears when `selectedCount > 0`.
- Displays selection count and custom action buttons.
- "Clear" button resets selection via `onClear` callback.

## Known limitations

- Does not auto-hide when selection is cleared—page-local code must conditionally render it based on `selectedCount`.
- No built-in bulk action execution logic—each action button must have its own `onClick` handler with validation and loading state.
- Does not manage selected row state itself—page-local code (table component) manages selection.

## Ask before building if:

- Bulk actions need loading states—add `isLoading` prop or disable buttons during async operations (page-local).
- The bar should auto-hide when selection clears—confirm page-local conditional rendering is handling this.
- Confirmation dialog is needed before bulk delete/dangerous actions—add `Dialog` wrapper around action buttons.

## Accessibility floor

- Selection count is announced.
- All action buttons are keyboard-accessible.
- "Clear" button has accessible name.

## Example

```tsx
import { BulkActionBar, Button, Checkbox } from "@neeve/dls";
import { useState } from "react";

export function UsersTable({ users }: Props) {
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

  const toggleAll = (checked: boolean) => {
    if (checked) {
      setSelectedIds(new Set(users.map((u) => u.id)));
    } else {
      setSelectedIds(new Set());
    }
  };

  const handleBulkDelete = async () => {
    await deleteUsers(Array.from(selectedIds));
    setSelectedIds(new Set());
  };

  return (
    <>
      <table>
        <thead>
          <tr>
            <th>
              <Checkbox
                checked={selectedIds.size === users.length}
                onCheckedChange={toggleAll}
              />
            </th>
            <th>Name</th>
            <th>Email</th>
          </tr>
        </thead>
        <tbody>
          {users.map((user) => (
            <tr key={user.id}>
              <td>
                <Checkbox
                  checked={selectedIds.has(user.id)}
                  onCheckedChange={(checked) => {
                    const newSelected = new Set(selectedIds);
                    if (checked) newSelected.add(user.id);
                    else newSelected.delete(user.id);
                    setSelectedIds(newSelected);
                  }}
                />
              </td>
              <td>{user.name}</td>
              <td>{user.email}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {selectedIds.size > 0 && (
        <BulkActionBar
          selectedCount={selectedIds.size}
          onClear={() => setSelectedIds(new Set())}
          actions={
            <Button variant="destructive" onClick={handleBulkDelete}>
              Delete {selectedIds.size} users
            </Button>
          }
        />
      )}
    </>
  );
}
```

### Used in one-portal: ChooseDevices.tsx

```tsx
<BulkActionBar
  selectedCount={selectedDevices.size}
  onClear={() => setSelectedDevices(new Set())}
  actions={
    <Button onClick={handleConfirm}>
      Continue with {selectedDevices.size} devices
    </Button>
  }
/>
```
