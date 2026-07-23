# HierarchyLoader (Standalone component)

**Layer:** Wrapper component (`standalones/components`) — skeleton loading state for hierarchical tree/list structures

Animated placeholder component that mimics the structure and visual hierarchy of a hierarchical list or tree view during data loading. Uses nested skeletal structures with varying depths.

## When to use

- Loading state for hierarchy pages (Organization > Portfolio > Site tree)
- Tree view skeleton during data fetch
- Hierarchical navigation skeleton
- Nested list loading states

## Props

No props — component is a pure loading state skeleton.

```tsx
const HierarchyLoader = () => {...}
```

## Capabilities

- Pre-built tree structure with realistic nesting levels (2-3 levels deep).
- Uses `SkeletonLoader` for animated placeholder lines simulating title and caption text.
- Mimics expanded state (all items visually expanded) for realistic preview.
- Fixed 4-item structure with varying nesting patterns.

## Known limitations

- Structure is hardcoded (fixed 4 root items with nested children)—not customizable per tree structure.
- Does not accept props to customize depth, item count, or nesting pattern.
- Only suitable for Org > Portfolio > Site hierarchy; not generic for arbitrary trees.

## Ask before building if:

- Custom nesting depth or item count needed—create parameterized skeleton or use `SkeletonLoader` directly.
- Tree structure differs from Org > Portfolio > Site—modify component or build custom skeleton.

## Accessibility floor

- Skeleton items are not interactive.
- `aria-busy="true"` should wrap this component in page context.
- Loading state should be announced to screen readers (e.g., "Loading hierarchy...).

## Examples

### Basic hierarchy loading state

```tsx
import { HierarchyLoader } from "@/standalones/components";
import { List } from "@neeve/dls";
import { useState, useEffect } from "react";

export function HierarchyPage() {
  const [isLoading, setIsLoading] = useState(true);
  const [hierarchy, setHierarchy] = useState(null);

  useEffect(() => {
    async function fetchHierarchy() {
      const data = await api.getHierarchy();
      setHierarchy(data);
      setIsLoading(false);
    }
    fetchHierarchy();
  }, []);

  return (
    <div aria-busy={isLoading}>
      {isLoading ? <HierarchyLoader /> : <List items={hierarchy} />}
    </div>
  );
}
```

### With Tanstack Query

```tsx
import { useQuery } from "@tanstack/react-query";
import { HierarchyLoader } from "@/standalones/components";
import { List } from "@neeve/dls";

export function OrganizationHierarchy() {
  const { data, isLoading } = useQuery({
    queryKey: ["organization-hierarchy"],
    queryFn: async () => {
      const res = await fetch("/api/hierarchy");
      return res.json();
    },
  });

  return isLoading ? <HierarchyLoader /> : <List items={data} />;
}
```

### In a sidebar

```tsx
import { HierarchyLoader } from "@/standalones/components";

export function Sidebar() {
  const { data, isLoading } = useHierarchy();

  return (
    <aside className="w-64 border-r p-4">
      <h3 className="mb-4 font-semibold">Organization</h3>
      {isLoading ? <HierarchyLoader /> : <List items={data} />}
    </aside>
  );
}
```
