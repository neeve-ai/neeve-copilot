# TableLoader (Standalone component)

**Layer:** Wrapper component (`standalones/components`) — skeleton loading state for TableV2

Animated placeholder component that mimics TableV2 structure during data fetching. Displays skeleton header and rows matching the actual table's column configuration and layout.

## When to use

- Table data loading state
- Data table skeleton while fetching rows
- Provides visual consistency with TableV2 styling
- Bridges between empty state and populated table

## Props

| Prop              | Type           | Required | Notes                                              |
| ----------------- | -------------- | -------- | -------------------------------------------------- |
| `table`           | `Table<TData>` | Yes      | TanStack Table instance (from `useReactTable`)     |
| `rowCount`        | `number`       | No       | Number of skeleton rows; default 10                |
| `pageSizeOptions` | `number[]`     | No       | Footer dropdown options; default [10, 25, 50, 100] |
| `truncateCell`    | `boolean`      | No       | Truncate cell content; default true                |
| `showCheckbox`    | `boolean`      | No       | Show checkbox column; default false                |

## Capabilities

- Matches TableV2 visual design (DLS styling, column widths, responsive layout).
- Reads table's header configuration to render matching skeleton columns.
- Skeleton rows animate with pulse effect (via `SkeletonLoader`).
- Footer with pagination controls (matching TableV2 pattern).
- Supports checkbox column visibility toggle.
- Fixed table layout with proper column sizing.
- Horizontal scroll support for wide tables.

## Known limitations

- Structure must match TableV2—does not work with custom table layouts.
- Row count is fixed—skeleton always renders `rowCount` rows (typically 10).
- Checkbox visibility must match actual table's `showCheckbox` setting.
- Footer pagination controls are static (no interaction)—purely visual during load.

## Ask before building if:

- Custom table layout is used (not TableV2)—build custom skeleton or use `SkeletonLoader` directly.
- Variable row count needed based on viewport height—detect viewport and adjust `rowCount` prop.
- Animated transition between skeleton and real table needed—wrap in CSS transition or Framer Motion.

## Accessibility floor

- Table structure is semantic (`<table>`, `<thead>`, `<tbody>`, `<th>`, `<td>`).
- Skeleton rows are not interactive.
- Container should have `aria-busy="true"` to indicate loading state.
- Table headers are announced.
- Checkboxes (if shown) are properly labeled.

## Examples

### Basic table loading state

```tsx
import { useReactTable, getCoreRowModel } from "@tanstack/react-table";
import { TableLoader } from "@/standalones/components";
import { TableV2 } from "@/standalones/components";
import { useQuery } from "@tanstack/react-query";

export function UsersTable() {
  const { data, isLoading } = useQuery({
    queryKey: ["users"],
    queryFn: async () => {
      const res = await fetch("/api/users");
      return res.json();
    },
  });

  const columns = [
    {
      accessorKey: "name",
      header: "Name",
      size: 200,
    },
    {
      accessorKey: "email",
      header: "Email",
      size: 300,
    },
    {
      accessorKey: "status",
      header: "Status",
      size: 100,
    },
  ];

  const table = useReactTable({
    data: data ?? [],
    columns,
    getCoreRowModel: getCoreRowModel(),
  });

  return isLoading ? (
    <TableLoader table={table} rowCount={10} />
  ) : (
    <TableV2 table={table} />
  );
}
```

### With custom page size options

```tsx
import {
  useReactTable,
  getCoreRowModel,
  getPaginationRowModel,
} from "@tanstack/react-table";
import { TableLoader } from "@/standalones/components";
import { useQuery } from "@tanstack/react-query";

export function PaginatedEndpointsTable() {
  const { data, isLoading } = useQuery({
    queryKey: ["endpoints"],
    queryFn: async () => {
      const res = await fetch("/api/endpoints");
      return res.json();
    },
  });

  const columns = [
    { accessorKey: "name", header: "Endpoint", size: 250 },
    { accessorKey: "protocol", header: "Protocol", size: 100 },
    { accessorKey: "port", header: "Port", size: 80 },
    { accessorKey: "status", header: "Status", size: 100 },
  ];

  const table = useReactTable({
    data: data ?? [],
    columns,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
  });

  return isLoading ? (
    <TableLoader table={table} rowCount={15} pageSizeOptions={[15, 30, 50]} />
  ) : (
    <TableV2 table={table} />
  );
}
```

### With checkbox selection

```tsx
import { useReactTable, getCoreRowModel } from "@tanstack/react-table";
import { TableLoader } from "@/standalones/components";
import { TableV2 } from "@/standalones/components";

export function BulkSelectTable() {
  const { data, isLoading } = useQuery({
    queryKey: ["items"],
    queryFn: async () => {
      const res = await fetch("/api/items");
      return res.json();
    },
  });

  const columns = [
    // Checkbox column handled by TableV2
    { accessorKey: "id", header: "ID", size: 80 },
    { accessorKey: "name", header: "Name", size: 250 },
    { accessorKey: "created", header: "Created", size: 150 },
  ];

  const table = useReactTable({
    data: data ?? [],
    columns,
    getCoreRowModel: getCoreRowModel(),
  });

  return isLoading ? (
    <TableLoader table={table} rowCount={10} showCheckbox={true} />
  ) : (
    <TableV2 table={table} showCheckbox={true} />
  );
}
```

### In a data grid container

```tsx
import { useReactTable, getCoreRowModel } from "@tanstack/react-table";
import { TableLoader } from "@/standalones/components";
import { TableV2 } from "@/standalones/components";
import { useQuery } from "@tanstack/react-query";

export function ConnectionsGrid() {
  const { data, isLoading, error } = useQuery({
    queryKey: ["connections"],
    queryFn: async () => {
      const res = await fetch("/api/connections");
      if (!res.ok) throw new Error("Failed to load");
      return res.json();
    },
  });

  const columns = [
    { accessorKey: "name", header: "Connection", size: 200 },
    { accessorKey: "type", header: "Type", size: 100 },
    { accessorKey: "lastActive", header: "Last Active", size: 150 },
  ];

  const table = useReactTable({
    data: data ?? [],
    columns,
    getCoreRowModel: getCoreRowModel(),
  });

  return (
    <div className="gap-dls-400 flex flex-col">
      {error && <AlertBanner type="error">{error.message}</AlertBanner>}

      {isLoading && <TableLoader table={table} rowCount={12} />}

      {!isLoading && data && <TableV2 table={table} />}

      {!isLoading && !data?.length && <EmptyState title="No connections" />}
    </div>
  );
}
```

### Adjust skeleton rows to viewport

```tsx
import { useEffect, useState } from "react";
import { TableLoader } from "@/standalones/components";

export function ResponsiveTableLoader({ table }: Props) {
  const [visibleRows, setVisibleRows] = useState(10);

  useEffect(() => {
    // Calculate rows visible in viewport (approximate)
    const headerHeight = 40;
    const rowHeight = 44;
    const availableHeight = window.innerHeight - headerHeight - 200; // 200px padding/footer
    const calculatedRows = Math.floor(availableHeight / rowHeight);
    setVisibleRows(Math.max(5, Math.min(calculatedRows, 20)));

    const handleResize = () => {
      const newHeight = window.innerHeight - headerHeight - 200;
      setVisibleRows(
        Math.max(5, Math.min(Math.floor(newHeight / rowHeight), 20))
      );
    };

    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  return <TableLoader table={table} rowCount={visibleRows} />;
}
```
