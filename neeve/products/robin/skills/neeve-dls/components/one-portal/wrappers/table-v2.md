# TableV2 (shared/components wrapper)

**Layer:** `shared/components` in the one-portal repo. Wraps DLS `Table`
(`components/dls/table.md`) and adds product-grade interactive behavior. This is what
"use the table from the DLS" should resolve to for any interactive/real data table.

## When to use

Any table showing real, interactive product data: lists of records with more than a
handful of rows, or any table where users need to reorder, resize, hide/show, sort,
filter, freeze, or select columns/rows.

## How it works — TanStack Table pattern

`TableV2` does **not** accept raw `columns` and `data` arrays directly. The caller
is responsible for constructing a [TanStack React Table](https://tanstack.com/table)
instance via `useReactTable()` and passing the resulting `table` object in. All
column configuration (resizability, reorderability, freezing, hiding, filtering) is
declared inside the column definitions via the `meta` field, not via top-level props
on `TableV2`.

```ts
// Minimal column definition shape (extend as needed)
{
  id: "name",
  accessorKey: "name",
  header: "Name",
  meta: {
    enableColumnResizing: true,
    enableColumnReordering: true,
    enableColumnHiding: true,
    enableColumnFreezing: false,
    isFixedColumn: false,      // true = cannot be reordered or hidden
    minWidth: 280,             // pixels; default 280, display columns default 50
    canFilter: true,
    enableDateFiltering: false,
    disableDropdown: false,
  },
}
```

## Companion components

`TableV2` is the rendering core. The following sibling components live in the same
`shared/components/table/` folder and extend specific slices of functionality.
**None are required** — include only the ones whose features you need for a given
screen.

### Quick-reference

| Component                | What it adds                                                              | Required for                                                                 |
| ------------------------ | ------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `TableV2Search`          | Global search bar, hint-engine suggestions, filter chips, recent searches | Any screen with a search/filter bar above the table                          |
| `ConfigureTableDialog`   | Column visibility / order / freeze / row-density settings dialog          | Screens that expose a "Configure table" settings button                      |
| `CsvExportWarningBanner` | Info banner when CSV export is row-capped                                 | Any screen with CSV export                                                   |
| `TableOnlyMenuItems`     | Menubar items: CSV export trigger + desktop/mobile view toggle            | Screens that include a `Menubar` toolbar above the table                     |
| `SelectionCell`          | First-column cell with checkbox + mobile chevron/link navigation          | Any column definition that needs checkbox row selection or mobile navigation |

### Internal only — do not import directly in page code

These components are used internally within the table family's own rendering. Pages
should never import them directly:

`CustomDateForm`, `DatePickerInput`, `TimePickerInput`, `Calendar`,
`lib/tableV2-storage`, `lib/tableV2-helpers`, `lib/tableV2-date-helper`

---

### `TableV2Search`

**Import:** `import { TableV2Search } from "@/shared/components/table/TableV2Search";`

Renders the search/filter bar that sits above `TableV2`. Integrates with the hint
engine for global-search suggestions and column-level filter suggestions, tracks
recent searches in storage, and renders active filter chips.

#### Props

| Prop                          | Type                                                                  | Required | Notes                                                                   |
| ----------------------------- | --------------------------------------------------------------------- | -------- | ----------------------------------------------------------------------- |
| `table`                       | `Table<TData>`                                                        | Yes      | Same TanStack table instance passed to `TableV2`.                       |
| `tableName`                   | `string`                                                              | Yes      | Same `tableName` passed to `TableV2` — used to persist recent searches. |
| `searchedValue`               | `string`                                                              | Yes      | Controlled global search value (the debounced query sent to the API).   |
| `setSearchedValue`            | `Dispatch<SetStateAction<string>>`                                    | Yes      |                                                                         |
| `enteredSearchValue`          | `string`                                                              | Yes      | The raw value in the input (before debounce).                           |
| `setEnteredSearchValue`       | `Dispatch<SetStateAction<string>>`                                    | Yes      |                                                                         |
| `debouncedSearch`             | `string`                                                              | Yes      | Debounced version of `enteredSearchValue`.                              |
| `searchFocused`               | `boolean`                                                             | Yes      | Whether the search input has focus.                                     |
| `setSearchFocused`            | `Dispatch<SetStateAction<boolean>>`                                   | Yes      |                                                                         |
| `searchKey`                   | `number`                                                              | Yes      | Incrementing key used to reset the input (e.g. on clear).               |
| `setSearchKey`                | `Dispatch<SetStateAction<number>>`                                    | Yes      |                                                                         |
| `pagination`                  | `{ pageIndex: number; pageSize: number }`                             | Yes      | Current pagination state.                                               |
| `setPagination`               | `Dispatch<SetStateAction<PaginationState>>`                           | Yes      | Resets to page 1 on new search.                                         |
| `recentSearches`              | `string[]`                                                            | Yes      | Recent searches shown in the dropdown.                                  |
| `setRecentSearches`           | `Dispatch<SetStateAction<string[]>>`                                  | Yes      |                                                                         |
| `searchResultCount`           | `number`                                                              | Yes      | Shown in the search results label.                                      |
| `excludedColumnsForFilter`    | `string[]`                                                            | Yes      | Column IDs excluded from the column-filter dropdown.                    |
| `setAppliedFilters`           | `Dispatch<SetStateAction<Record<string, string>>>`                    | Yes      |                                                                         |
| `filterChips`                 | `{ filter_key: string; filter_value: string; filter_name: string }[]` | Yes      | Active filter chips rendered below the search bar.                      |
| `setFilterChips`              | `Dispatch<SetStateAction<FilterChipItem[]>>`                          | Yes      |                                                                         |
| `handleFilterSuggestionClick` | `(filter_key, filter_value, filter_name) => void`                     | Yes      | Same handler passed to `TableV2`.                                       |
| `isLoading`                   | `boolean`                                                             | No       | Shows a loading state in the suggestion list.                           |
| `filterHintSuggestions`       | `({ columnId, suggestions }) => string[]`                             | No       | Transforms raw hint-engine suggestions per column.                      |

---

### `ConfigureTableDialog`

**Import:** `import { ConfigureTableDialog } from "@/shared/components/table/ConfigureTableDialog";`

A dialog that lets users reorder columns (drag-and-drop), toggle column visibility,
freeze/unfreeze columns, and toggle row density. Reads and writes to the same
`useTableStorage` instance used by `TableV2`, so changes persist automatically.

#### Props

| Prop                          | Type                                | Required | Notes                                             |
| ----------------------------- | ----------------------------------- | -------- | ------------------------------------------------- |
| `openConfigureTableDialog`    | `boolean`                           | Yes      | Controls dialog open/close state.                 |
| `setOpenConfigureTableDialog` | `Dispatch<SetStateAction<boolean>>` | Yes      |                                                   |
| `tableName`                   | `string`                            | Yes      | Same `tableName` passed to `TableV2`.             |
| `table`                       | `Table<TData>`                      | Yes      | Same TanStack table instance passed to `TableV2`. |
| `enableRowDensity`            | `boolean`                           | Yes      | Current row-density toggle state (true = dense).  |
| `setEnableRowDensity`         | `Dispatch<SetStateAction<boolean>>` | Yes      |                                                   |

---

### `CsvExportWarningBanner`

**Import:** `import { CsvExportWarningBanner } from "@/shared/components/table/CsvExportWarningBanner";`

Renders a DLS `AlertBanner` (info type) when a CSV export was silently capped at
`MAX_CSV_EXPORT_ROWS`. Reads state from `useTableStore` (Zustand) — **no props**.
The banner auto-dismisses and cleans up on unmount. Place it above or below the
table; it renders nothing when no warning is active.

---

### `TableOnlyMenuItems`

**Import:** `import { TableOnlyMenuItems } from "@/shared/components/table/TableOnlyMenuItems";`

A set of `MenubarItem` entries designed to be composed inside a DLS `Menubar`
toolbar above the table. Provides two items: CSV export (disabled while exporting
or when `totalCount === 0`) and a desktop/mobile table-view toggle.

#### Props

| Prop                               | Type                                | Required | Notes                                                    |
| ---------------------------------- | ----------------------------------- | -------- | -------------------------------------------------------- |
| `isExportingCSV`                   | `boolean`                           | Yes      | Disables the export item while an export is in progress. |
| `totalCount`                       | `number`                            | Yes      | Disables the export item when zero.                      |
| `handleExportCSV`                  | `() => Promise<void>`               | Yes      | Called when the user clicks "Export CSV".                |
| `showDesktopTableInSmallScreen`    | `boolean`                           | Yes      | Current desktop-view-on-mobile toggle state.             |
| `setShowDesktopTableInSmallScreen` | `Dispatch<SetStateAction<boolean>>` | Yes      |                                                          |

---

### `SelectionCell`

**Import:** `import { SelectionCell } from "@/shared/components/table/SelectionCell";`

Used inside a column definition's `cell` renderer to produce the first column of
a row. On desktop it renders a DLS `Checkbox`; on mobile (when not in forced-desktop
mode) it renders either a `Button` chevron (for `onClick`-based navigation) or a
Next.js `Link` chevron (for `href`-based navigation). Use this whenever a column
needs checkbox row selection and/or mobile row-navigation.

#### Props

| Prop                            | Type                         | Required | Default | Notes                                                                       |
| ------------------------------- | ---------------------------- | -------- | ------- | --------------------------------------------------------------------------- |
| `name`                          | `string`                     | Yes      | —       | Accessible name for the checkbox.                                           |
| `checked`                       | `boolean`                    | Yes      | —       | Checkbox checked state.                                                     |
| `onCheckedChange`               | `(checked: boolean) => void` | Yes      | —       |                                                                             |
| `disabled`                      | `boolean`                    | Yes      | —       | Disables the checkbox.                                                      |
| `showDesktopTableInSmallScreen` | `boolean`                    | Yes      | —       | When `true`, suppresses the mobile chevron.                                 |
| `href`                          | `string`                     | No       | —       | If provided, renders a `<Link>` chevron on mobile for navigation.           |
| `onClick`                       | `() => void`                 | No       | —       | If provided (and no `href`), renders a `<button>` chevron on mobile.        |
| `disabledButton`                | `boolean`                    | No       | `false` | Disables the mobile chevron button.                                         |
| `showCheckbox`                  | `boolean`                    | No       | `false` | Shows the checkbox column; if `false`, only the mobile chevron is rendered. |

## Props

### Required

| Prop                          | Type                                                                      | Notes                                                                                                                    |
| ----------------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `tableName`                   | `string`                                                                  | Unique key used to persist column preferences (order, sizing, visibility) in storage.                                    |
| `table`                       | `Table<TData>`                                                            | The TanStack React Table instance created by the caller via `useReactTable()`.                                           |
| `showLoader`                  | `boolean`                                                                 | When `true`, renders a skeleton `TableLoader` instead of real rows.                                                      |
| `loadingPreferences`          | `boolean`                                                                 | When `true` (preferences still loading from storage), also renders the skeleton loader.                                  |
| `totalRows`                   | `number`                                                                  | Total row count used by the pagination footer.                                                                           |
| `pageSizeOptions`             | `number[]`                                                                | Options shown in the "rows per page" select (e.g. `[10, 25, 50]`).                                                       |
| `setPagination`               | `Dispatch<SetStateAction<PaginationState>>`                               | Setter from the caller's `useState<PaginationState>`. Wired to page-size and page-navigation controls.                   |
| `setCurrentColumnDropdown`    | `Dispatch<SetStateAction<string \| null>>`                                | Lets the parent track which column header dropdown is open (needed for external close coordination).                     |
| `filterColumnValue`           | `string`                                                                  | Current value in the active column filter input.                                                                         |
| `setFilterColumnValue`        | `Dispatch<SetStateAction<string>>`                                        | Setter for the filter input value.                                                                                       |
| `handleFilterSuggestionClick` | `(filter_key: string, filter_value: string, filter_name: string) => void` | Called when the user picks a filter suggestion chip. Also resets pagination to page 1 internally.                        |
| `filterChips`                 | `{ filter_key: string; filter_value: string; filter_name: string }[]`     | Active filter chips shown in the filter bar. Drives clearing of date-range selections when chips are removed externally. |

### Optional

| Prop                       | Type                      | Default | Notes                                                       |
| -------------------------- | ------------------------- | ------- | ----------------------------------------------------------- |
| `searchTerm`               | `string`                  | —       | When provided, cells highlight matching text.               |
| `truncateCell`             | `boolean`                 | `true`  | Whether to truncate overflowing cell text with an ellipsis. |
| `onRowClick`               | `(row: TData) => void`    | —       | Handler for row click events.                               |
| `isRowClickable`           | `(row: TData) => boolean` | —       | Controls whether a given row renders with click affordance. |
| `showCheckbox`             | `boolean`                 | `false` | Shows a selection checkbox column as the first column.      |
| `hintSuggestions`          | `string[]`                | `[]`    | Autocomplete suggestions shown in the filter input.         |
| `isHintSuggestionsLoading` | `boolean`                 | `false` | Shows a loading state inside the filter suggestion list.    |

## Capabilities

- **Column reorder** — drag-and-drop via `@dnd-kit`, per-column via `meta.enableColumnReordering`. Fixed columns (`meta.isFixedColumn`) cannot be moved.
- **Column resize** — mouse and touch drag on column borders, per-column via `meta.enableColumnResizing`. Respects `meta.minWidth` (default 280px, display columns 50px).
- **Column hide/show** — via column header dropdown, per-column via `meta.enableColumnHiding`. Fixed and display columns are excluded.
- **Column freeze/pin** — sticky left positioning via TanStack `columnPinning`, per-column via `meta.enableColumnFreezing`. Left/right scroll shadows indicate frozen boundary.
- **Pagination** — built-in page-size selector and prev/next navigation. Supports both client-side and server-side pagination (caller controls `manualPagination` on the `useReactTable` instance).
- **Column filter** — per-column filter input with hint suggestions, per-column via `meta.canFilter`.
- **Date range filter** — calendar date-range picker, per-column via `meta.enableDateFiltering`.
- **Row selection** — checkbox column via `showCheckbox` prop; wiring to a `BulkActionBar` is the caller's responsibility.
- **Sort** — via TanStack column sorting; the sort icon and tooltip are rendered by `TableV2`. Caller configures sorting on the `useReactTable` instance.
- **Horizontal scroll shadows** — visual left/right gradient shadows auto-appear when content is scrolled and frozen columns exist.
- **Preference persistence** — column order, sizing, and visibility are automatically saved and restored via `useTableStorage`.
- **Empty state** — renders DLS `EmptyState` automatically when rows are zero.
- **Loading state** — renders `TableLoader` skeleton when `showLoader` or `loadingPreferences` is true.

## Known limitations

- **Nested/expandable rows** — not supported.
- **Multi-level/grouped headers** — not supported.
- **Row grouping** — not supported.

## If the request exceeds these limitations

Follow SKILL.md Step 2 exactly: do not build the missing behavior into the consuming
page. Ask whether to extend `shared/components/table/TableV2.tsx` first. This is the
mechanism that keeps one wrapper as the source of truth instead of every prototype
growing its own divergent table logic.

## Example

```tsx
import { TableV2 } from "@/shared/components/table/TableV2";
import {
  useReactTable,
  getCoreRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  type ColumnDef,
  type PaginationState,
} from "@tanstack/react-table";
import { useState } from "react";

const columns: ColumnDef<MyRow>[] = [
  {
    id: "name",
    accessorKey: "name",
    header: "Name",
    meta: {
      enableColumnResizing: true,
      enableColumnReordering: true,
      enableColumnHiding: true,
    },
  },
  // ...more columns
];

function MyTable({ data }: { data: MyRow[] }) {
  const [pagination, setPagination] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 25,
  });
  const [currentColumnDropdown, setCurrentColumnDropdown] = useState<
    string | null
  >(null);
  const [filterColumnValue, setFilterColumnValue] = useState("");
  const [filterChips, setFilterChips] = useState([]);

  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    state: { pagination },
    onPaginationChange: setPagination,
  });

  return (
    <TableV2
      tableName="my-table"
      table={table}
      showLoader={false}
      loadingPreferences={false}
      totalRows={data.length}
      pageSizeOptions={[10, 25, 50]}
      setPagination={setPagination}
      setCurrentColumnDropdown={setCurrentColumnDropdown}
      filterColumnValue={filterColumnValue}
      setFilterColumnValue={setFilterColumnValue}
      handleFilterSuggestionClick={(key, value, name) => {
        setFilterChips((prev) => [
          ...prev,
          { filter_key: key, filter_value: value, filter_name: name },
        ]);
      }}
      filterChips={filterChips}
    />
  );
}
```

## Example — with `TableV2Search` and `ConfigureTableDialog`

Builds on the minimal example above. Adds:

- A search/filter bar via `TableV2Search`
- A "Configure table" button that opens `ConfigureTableDialog`
- Row-density state wired into the dialog

```tsx
import { useState } from "react";
import {
  useReactTable,
  getCoreRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  type ColumnDef,
  type PaginationState,
} from "@tanstack/react-table";
import { TableV2 } from "@/shared/components/table/TableV2";
import { TableV2Search } from "@/shared/components/table/TableV2Search";
import { ConfigureTableDialog } from "@/shared/components/table/ConfigureTableDialog";
import { Button } from "@neeve/dls";
import { useDebounce } from "@/shared/hooks/useDebounce"; // project debounce hook

const TABLE_NAME = "user-list-table";

const columns: ColumnDef<MyRow>[] = [
  {
    id: "name",
    accessorKey: "name",
    header: "Name",
    meta: {
      enableColumnResizing: true,
      enableColumnReordering: true,
      enableColumnHiding: true,
      enableColumnFreezing: false,
      isFixedColumn: false,
      canFilter: true,
    },
  },
  // ...more columns
];

function MyTablePage({
  data,
  totalCount,
}: {
  data: MyRow[];
  totalCount: number;
}) {
  // ── Pagination ─────────────────────────────────────────────────────────────
  const [pagination, setPagination] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 25,
  });

  // ── Column filter (per-column header dropdown) ─────────────────────────────
  const [currentColumnDropdown, setCurrentColumnDropdown] = useState<
    string | null
  >(null);
  const [filterColumnValue, setFilterColumnValue] = useState("");
  const [filterChips, setFilterChips] = useState<FilterChipItem[]>([]);
  const [appliedFilters, setAppliedFilters] = useState<Record<string, string>>(
    {}
  );

  const handleFilterSuggestionClick = (
    filter_key: string,
    filter_value: string,
    filter_name: string
  ) => {
    setFilterChips((prev) => [
      ...prev,
      { filter_key, filter_value, filter_name },
    ]);
    setAppliedFilters((prev) => ({ ...prev, [filter_key]: filter_value }));
    setPagination((prev) => ({ ...prev, pageIndex: 0 }));
  };

  // ── Search ─────────────────────────────────────────────────────────────────
  const [enteredSearchValue, setEnteredSearchValue] = useState("");
  const [searchedValue, setSearchedValue] = useState("");
  const debouncedSearch = useDebounce(enteredSearchValue, 300);
  const [searchFocused, setSearchFocused] = useState(false);
  const [searchKey, setSearchKey] = useState(0);
  const [recentSearches, setRecentSearches] = useState<string[]>([]);

  // ── Configure table dialog ─────────────────────────────────────────────────
  const [openConfigureTableDialog, setOpenConfigureTableDialog] =
    useState(false);
  const [enableRowDensity, setEnableRowDensity] = useState(false);

  // ── TanStack table instance ────────────────────────────────────────────────
  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    manualPagination: true, // server-side pagination
    pageCount: Math.ceil(totalCount / pagination.pageSize),
    state: { pagination },
    onPaginationChange: setPagination,
  });

  return (
    <div className="gap-dls-400 flex flex-col">
      {/* ── Toolbar: search bar + configure button ── */}
      <div className="gap-dls-200 flex items-start">
        <TableV2Search
          table={table}
          tableName={TABLE_NAME}
          searchedValue={searchedValue}
          setSearchedValue={setSearchedValue}
          enteredSearchValue={enteredSearchValue}
          setEnteredSearchValue={setEnteredSearchValue}
          debouncedSearch={debouncedSearch}
          searchFocused={searchFocused}
          setSearchFocused={setSearchFocused}
          searchKey={searchKey}
          setSearchKey={setSearchKey}
          pagination={pagination}
          setPagination={setPagination}
          recentSearches={recentSearches}
          setRecentSearches={setRecentSearches}
          searchResultCount={totalCount}
          excludedColumnsForFilter={[]}
          setAppliedFilters={setAppliedFilters}
          filterChips={filterChips}
          setFilterChips={setFilterChips}
          handleFilterSuggestionClick={handleFilterSuggestionClick}
        />

        <Button
          variant="secondary"
          size="small"
          onClick={() => setOpenConfigureTableDialog(true)}
        >
          Configure table
        </Button>
      </div>

      {/* ── Table ── */}
      <TableV2
        tableName={TABLE_NAME}
        table={table}
        showLoader={false}
        loadingPreferences={false}
        totalRows={totalCount}
        pageSizeOptions={[10, 25, 50]}
        setPagination={setPagination}
        setCurrentColumnDropdown={setCurrentColumnDropdown}
        filterColumnValue={filterColumnValue}
        setFilterColumnValue={setFilterColumnValue}
        handleFilterSuggestionClick={handleFilterSuggestionClick}
        filterChips={filterChips}
        searchTerm={searchedValue}
      />

      {/* ── Configure table dialog ── */}
      <ConfigureTableDialog
        openConfigureTableDialog={openConfigureTableDialog}
        setOpenConfigureTableDialog={setOpenConfigureTableDialog}
        tableName={TABLE_NAME}
        table={table}
        enableRowDensity={enableRowDensity}
        setEnableRowDensity={setEnableRowDensity}
      />
    </div>
  );
}
```

**Key points illustrated above:**

- `TABLE_NAME` is a single constant shared by `TableV2`, `TableV2Search`, and `ConfigureTableDialog` — all three must receive the exact same value so preference storage is consistent.
- `debouncedSearch` is derived from `enteredSearchValue`; the debounced value is what you pass to your API query, not `enteredSearchValue` directly.
- `handleFilterSuggestionClick` is shared between `TableV2Search` (where the user picks a filter suggestion) and `TableV2` (where column-header filter dropdowns fire the same event) — wire both to the same handler.
- `ConfigureTableDialog` is mounted at all times (not conditionally) so it can preserve its own internal drag-and-drop state across opens/closes; `openConfigureTableDialog` controls visibility.
- `searchTerm` on `TableV2` pipes the active search value into the table for in-cell text highlighting.
