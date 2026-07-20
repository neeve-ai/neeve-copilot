# Tag (DLS component) / Chip

**Layer:** `@neeve/dls` design system primitive

Dismissible or static labels for categorizing content. Use for tags, statuses, and removable selections.

## When to use

- Status badges (Active, Inactive, Pending)
- Category tags (Network, Endpoint, Node)
- Active filters shown as removable chips
- User-selected items that can be removed
- Skill or permission labels

## Props

| Prop        | Type                                      | Required | Notes                                        |
| ----------- | ----------------------------------------- | -------- | -------------------------------------------- |
| `label`     | `string \| ReactNode`                     | Yes      | Tag text                                     |
| `variant`   | `"default" \| "outline" \| "destructive"` | No       | Visual style                                 |
| `onRemove`  | `() => void`                              | No       | Callback when X clicked; omit for static tag |
| `icon`      | `ReactNode`                               | No       | Icon before label                            |
| `className` | `string`                                  | No       | Additional Tailwind classes                  |

## Capabilities

- Displays labels with optional dismiss button (via `onRemove`).
- Supports multiple visual variants (default, outline, destructive).
- Integrates with form state via `onRemove` callback for tag management.

## Known limitations

- No autocomplete or suggestion UI—use `ComboBox` or `MultiSelect` for that.
- Does not auto-manage a list of tags—page-local code must track tag array state and call `onRemove` to filter.
- Not interactive beyond the remove button—if a tag should be clickable (e.g., filter by tag), wrap it or use page-local click handler.

## Ask before building if:

- A tag cloud or autocomplete tag input is needed—clarify if this should be `MultiSelect` or a custom form component.
- Tags should have click behavior (e.g., "click to filter")—add page-local `onClick` handler or wrap in a button.
- Many tags are added dynamically—confirm page-local state management handles the array properly and re-renders correctly.

## Accessibility floor

- Remove button has `aria-label="Remove [tag-text]"` automatically (verify in implementation).
- `label` text is announced.

## Examples

### Static status tags

```tsx
import { Tag } from "@neeve/dls";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faCircle } from "@view/pro-solid-svg-icons";

export function StatusDisplay({
  status,
}: {
  status: "active" | "inactive" | "pending";
}) {
  const statusConfig = {
    active: { label: "Active", color: "text-success-primary" },
    inactive: { label: "Inactive", color: "text-foreground-secondary" },
    pending: { label: "Pending", color: "text-warning-primary" },
  };

  const config = statusConfig[status];

  return (
    <Tag
      label={config.label}
      icon={
        <FontAwesomeIcon
          icon={faCircle}
          className={`mr-dls-100 ${config.color}`}
        />
      }
    />
  );
}
```

### Removable filter chips

```tsx
import { Tag } from "@neeve/dls";

export function FilterChips({ filters, onRemoveFilter }: Props) {
  return (
    <div className="gap-dls-200 flex flex-wrap">
      {filters.map((filter) => (
        <Tag
          key={filter.id}
          label={`${filter.name}: ${filter.value}`}
          onRemove={() => onRemoveFilter(filter.id)}
          variant="outline"
        />
      ))}
    </div>
  );
}
```

### Used in one-portal: ConnectToSystemNetwork.tsx

```tsx
<Tag label="Active" variant="default" />
```
