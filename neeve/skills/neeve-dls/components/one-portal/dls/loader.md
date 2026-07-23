# Loader (DLS component)

**Layer:** `@neeve/dls` design system primitive

Animated spinner for loading states. Use when data is being fetched or processing is underway.

## When to use

- Page load spinners
- Inline loading within buttons (loading state)
- Data fetch indicators in tables
- Process/task completion spinners
- Form submission feedback

## Props

| Prop        | Type                             | Required | Notes                            |
| ----------- | -------------------------------- | -------- | -------------------------------- |
| `size`      | `"small" \| "medium" \| "large"` | No       | Spinner size; default `"medium"` |
| `className` | `string`                         | No       | Additional Tailwind classes      |

## Capabilities

- Displays animated loading spinner with three size variants.
- No state management—it's a pure visual component that always displays.

## Known limitations

- No auto-hide or timeout—page-local code must conditionally render it based on loading state.
- Does not show progress percentage—just a generic "loading in progress" indicator.

## Ask before building if:

- Progress or completion percentage should be shown—use a progress bar component or custom UI instead.
- The loader should auto-hide after a timeout—add page-local setTimeout logic, not a component feature.

## Accessibility floor

- Component itself has no text—wrap in a container with `aria-label="Loading"` or `aria-busy="true"` for screen reader users.

## Examples

### Centered page loader

```tsx
import { Loader } from "@neeve/dls";

export function EndpointsPage() {
  const { isLoading, data } = useEndpoints();

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <Loader size="large" />
      </div>
    );
  }

  return <EndpointsTable data={data} />;
}
```

### Inline loading in table

```tsx
import { Loader, EmptyState } from "@neeve/dls";

export function UsersList() {
  const { isLoading, data } = useUsers();

  if (isLoading) {
    return (
      <div className="py-dls-800 flex justify-center">
        <Loader size="medium" />
      </div>
    );
  }

  if (data.length === 0) {
    return <EmptyState title="No users" />;
  }

  return <UsersTable data={data} />;
}
```

### Loading state in button

```tsx
import { Button, Loader } from "@neeve/dls";
import { useState } from "react";

export function DeleteUserButton({ userId }: { userId: string }) {
  const [isDeleting, setIsDeleting] = useState(false);

  const handleDelete = async () => {
    setIsDeleting(true);
    try {
      await deleteUser(userId);
    } finally {
      setIsDeleting(false);
    }
  };

  if (isDeleting) {
    return (
      <Button disabled>
        <Loader size="small" />
        <span className="ml-dls-200">Deleting...</span>
      </Button>
    );
  }

  return <Button onClick={handleDelete}>Delete</Button>;
}
```

### Used in one-portal: ConnectionStatusIndicator.tsx

```tsx
{
  isLoading && <Loader size="small" />;
}
```
