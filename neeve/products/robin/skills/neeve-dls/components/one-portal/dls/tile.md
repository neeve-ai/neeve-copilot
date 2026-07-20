# Tile (DLS component)

**Layer:** `@neeve/dls` design system primitive

Card container for grouping related content. Use for visual organization and card-based layouts.

## When to use

- Summary cards (connection details, endpoint info)
- Card-based layouts (dashboard cards)
- Grouped form sections
- Content containers with borders
- List item cards

## Props

| Prop          | Type         | Required | Notes                          |
| ------------- | ------------ | -------- | ------------------------------ |
| `children`    | `ReactNode`  | Yes      | Card content                   |
| `title`       | `string`     | No       | Card heading                   |
| `description` | `string`     | No       | Optional subtitle              |
| `footer`      | `ReactNode`  | No       | Footer content (buttons, etc.) |
| `className`   | `string`     | No       | Additional Tailwind classes    |
| `clickable`   | `boolean`    | No       | Adds click affordance          |
| `onClick`     | `() => void` | No       | Callback when clicked          |

## Capabilities

- Container with border and padding for grouped content.
- Optional title and description header.
- Optional footer slot for buttons or metadata.
- `clickable` variant adds hover affordance (pointer cursor, lifted shadow).

## Known limitations

- Not a link component—if tile navigates to a route, wrap in `<Link>` or use `onClick` with `useRouter`.
- No shadow/elevation variants beyond `clickable`—for custom styling, use `className`.

## Ask before building if:

- Tile should navigate to a route—wrap in `<Link>` or use `onClick` with `useRouter.push()`.
- Custom styling or shadows are needed—add via `className` with Tailwind utilities.

## Accessibility floor

- If `clickable` and keyboard-interactive, add `role="button"` and `onClick` handler.
- Title and description are announced.
- If clickable, ensure tab-accessible (use `<button>` wrapper, not div).

## Examples

### Summary card

```tsx
import { Tile } from "@neeve/dls";
import { Tag } from "@neeve/dls";

export function EndpointSummary({ endpoint }: Props) {
  return (
    <Tile title={endpoint.name} description={endpoint.type}>
      <div className="gap-dls-300 flex flex-col">
        <div>
          <span className="text-foreground-secondary">IP Address:</span>
          <span className="ml-dls-200">{endpoint.ipAddress}</span>
        </div>
        <div>
          <span className="text-foreground-secondary">Status:</span>
          <span className="ml-dls-200">
            <Tag label={endpoint.status} />
          </span>
        </div>
      </div>
    </Tile>
  );
}
```

### Clickable card in grid

```tsx
import { Tile } from "@neeve/dls";
import { useRouter } from "next/navigation";

export function ConnectionGrid({ connections }: Props) {
  const router = useRouter();

  return (
    <div className="gap-dls-400 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
      {connections.map((conn) => (
        <Tile
          key={conn.id}
          clickable
          onClick={() => router.push(`/connections/${conn.id}`)}
        >
          <div>
            <h3 className="font-semibold">{conn.name}</h3>
            <p className="text-foreground-secondary">{conn.type}</p>
          </div>
        </Tile>
      ))}
    </div>
  );
}
```

### Used in one-portal: EndpointConfirmation.tsx

```tsx
<Tile title={endpoint.name}>{/* content */}</Tile>
```
