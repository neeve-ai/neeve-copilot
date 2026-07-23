# List / TreeNodeProps (DLS component)

**Layer:** `@neeve/dls` design system primitive

Hierarchical list renderer for tree views. Supports nested items, expansion, and selection.

## When to use

- Hierarchical navigation (Org → Portfolio → Site)
- File/folder trees
- Category hierarchies
- Org structure visualization

## Props / Types

| Property   | Type                   | Notes                    |
| ---------- | ---------------------- | ------------------------ |
| `id`       | `string`               | Unique identifier        |
| `label`    | `ReactNode`            | Display text             |
| `children` | `TreeNodeProps[]`      | Nested items             |
| `expanded` | `boolean`              | Initially expanded state |
| `onExpand` | `(id: string) => void` | Expand/collapse callback |

## Capabilities

- Renders hierarchical tree of items with expand/collapse toggle.
- Keyboard navigation (Arrow keys, Enter to expand, Space to select).
- Nested children render recursively.

## Known limitations

- No selection state management built-in—page-local code must manage selected items.
- No drag-and-drop reordering—requires custom integration (react-beautiful-dnd, etc.).
- No virtualization—for trees with 100+ nodes, performance may degrade; use custom virtualized tree.

## Ask before building if:

- Item selection with bulk actions needed—add `selected` prop and use `BulkActionBar` for actions.
- Reordering/drag-drop needed—integrate with dnd library and manage order in page-local state.
- Tree has 100+ nodes and is slow—use virtualized tree or implement custom windowing.

## Accessibility floor

- Tree is semantic (uses `role="tree"`, `role="treeitem"`).
- Keyboard navigation (Arrow keys, Enter, Space) fully supported.
- Expand/collapse state is announced.
- Nesting level is indicated to screen readers.

## Example

```tsx
import { List, type TreeNodeProps } from "@neeve/dls";

export function HierarchyTree({ org }: Props) {
  const [expanded, setExpanded] = useState<Record<string, boolean>>({});

  const handleExpand = (id: string) => {
    setExpanded((prev) => ({
      ...prev,
      [id]: !prev[id],
    }));
  };

  const treeData: TreeNodeProps[] = [
    {
      id: org.id,
      label: org.name,
      expanded: expanded[org.id],
      onExpand: () => handleExpand(org.id),
      children: org.portfolios.map((pf) => ({
        id: pf.id,
        label: pf.name,
        expanded: expanded[pf.id],
        onExpand: () => handleExpand(pf.id),
        children: pf.sites.map((site) => ({
          id: site.id,
          label: site.name,
        })),
      })),
    },
  ];

  return <List items={treeData} />;
}
```

### Used in one-portal: ConnectionsHierarchy.tsx

```tsx
<List items={hierarchyData} />
```
