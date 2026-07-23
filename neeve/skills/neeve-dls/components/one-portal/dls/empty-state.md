# EmptyState (DLS component)

**Layer:** `@neeve/dls` design system primitive

Friendly message when a list, table, or section has no content. Guides users on what to do next.

## When to use

- Empty data lists or tables
- 404 or not-found pages
- Initial state of a feature (no nodes yet)
- Filtered results with zero matches
- Access denied or no permissions

## Props

| Prop          | Type                             | Required | Notes                       |
| ------------- | -------------------------------- | -------- | --------------------------- |
| `icon`        | `IconDefinition`                 | No       | FontAwesome icon to display |
| `title`       | `string`                         | Yes      | Heading text                |
| `description` | `string \| ReactNode`            | No       | Explanation or suggestions  |
| `action`      | `ReactNode`                      | No       | Action button(s) to display |
| `size`        | `"small" \| "medium" \| "large"` | No       | Sizing; default `"medium"`  |
| `className`   | `string`                         | No       | Additional Tailwind classes |

## Capabilities

- Displays friendly, centered message for zero-content states.
- Supports icon, title, description, and action button(s).
- Three size variants for flexible layout contexts.

## Known limitations

- Not interactive beyond the optional action button—if complex UI is needed, use a custom layout instead.
- Icon is decoration only—no accessibility features beyond visual.

## Ask before building if:

- Multiple action buttons are needed—pass an array or custom button group in `action` prop.
- The empty state has complex layout or many actions—consider page-local custom layout instead of using `EmptyState`.

## Accessibility floor

- `title` is announced as a heading.
- `description` and `action` are accessible.
- Icon is decorative (no `alt` text needed).

## Examples

### Empty endpoints list with action

```tsx
import { EmptyState, Button } from "@neeve/dls";
import { faPlus } from "@view/pro-regular-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

export function EndpointsList() {
  const endpoints = useEndpoints();

  if (endpoints.length === 0) {
    return (
      <EmptyState
        icon={faPlus}
        title="No endpoints yet"
        description="Add your first endpoint to get started managing your network infrastructure."
        action={
          <Button variant="primary" onClick={() => openAddEndpointDialog()}>
            <FontAwesomeIcon icon={faPlus} className="mr-dls-200" />
            Add endpoint
          </Button>
        }
      />
    );
  }

  return <EndpointsTable data={endpoints} />;
}
```

### Search results with no matches

```tsx
import { EmptyState } from "@neeve/dls";
import { faMagnifyingGlass } from "@view/pro-regular-svg-icons";

export function SearchResults({ query, results }: Props) {
  if (results.length === 0) {
    return (
      <EmptyState
        icon={faMagnifyingGlass}
        title="No results found"
        description={`No endpoints match "${query}". Try adjusting your search terms.`}
        size="small"
      />
    );
  }

  return <table>{/* results */}</table>;
}
```

### Access denied message

```tsx
import { EmptyState, Button } from "@neeve/dls";
import { faLock } from "@view/pro-solid-svg-icons";

export function UnauthorizedAccess() {
  return (
    <EmptyState
      icon={faLock}
      title="Access denied"
      description="You don't have permission to view this page. Contact an administrator."
      action={
        <Button variant="secondary" onClick={() => router.push("/")}>
          Return home
        </Button>
      }
    />
  );
}
```

### Used in one-portal: ListUsers.tsx

```tsx
{
  users.length === 0 ? (
    <EmptyState
      title="No users"
      description="No users in this organization. Add your first user to get started."
      action={
        <Button variant="primary" onClick={() => setOpenAddUserDialog(true)}>
          Add user
        </Button>
      }
    />
  ) : (
    <UsersTable data={users} />
  );
}
```
