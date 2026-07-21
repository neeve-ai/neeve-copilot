# SearchBar (DLS component)

**Layer:** `@neeve/dls` design system primitive

Full-width search input with icon and optional clear button. Typically placed in page headers for filtering/searching.

## When to use

- Page-level search (search endpoints, nodes, etc.)
- List filtering
- Global search inputs
- Persistent search in headers or toolbars

## Props

| Prop          | Type                      | Required | Notes                              |
| ------------- | ------------------------- | -------- | ---------------------------------- |
| `value`       | `string`                  | Yes      | Current search value               |
| `onChange`    | `(value: string) => void` | Yes      | Callback on input change           |
| `placeholder` | `string`                  | No       | Placeholder text                   |
| `onClear`     | `() => void`              | No       | Callback when clear button clicked |
| `disabled`    | `boolean`                 | No       | Disables the search                |
| `className`   | `string`                  | No       | Additional Tailwind classes        |

## Capabilities

- Full-width search input with built-in search icon.
- Optional clear button (X) that triggers `onClear` callback.
- Supports debouncing via page-local state management (component doesn't debounce internally).

## Known limitations

- No built-in debouncing—if API calls should be debounced, add `useMemo` + `useEffect` with debounce logic in page-local code.
- Not autocomplete or suggestion UI—use `ComboBox` for that.
- Does not filter a list itself—page-local code must handle filtering based on `value`.

## Ask before building if:

- Autocomplete/suggestions should appear as user types—use `ComboBox` instead.
- Debouncing or throttling is needed—add page-local debounce hook, not a component feature.
- The search should trigger API calls—confirm page-local effect handles debouncing and error states.

## Accessibility floor

- Search icon is decorative.
- Clear button has accessible name ("Clear search" or similar).
- Input field should have `aria-label` if no visible label is present.

## Examples

### Basic page search

```tsx
import { SearchBar, List } from "@neeve/dls";
import { useState, useMemo } from "react";

export function EndpointSearch({ allEndpoints }: Props) {
  const [searchQuery, setSearchQuery] = useState("");

  const filtered = useMemo(
    () =>
      allEndpoints.filter((ep) =>
        ep.name.toLowerCase().includes(searchQuery.toLowerCase())
      ),
    [allEndpoints, searchQuery]
  );

  return (
    <div className="gap-dls-400 flex flex-col">
      <SearchBar
        value={searchQuery}
        onChange={setSearchQuery}
        placeholder="Search endpoints by name..."
        onClear={() => setSearchQuery("")}
      />
      <List items={filtered} />
    </div>
  );
}
```

### Used in one-portal: ShowConnections.tsx

```tsx
<SearchBar
  value={searchTerm}
  onChange={setSearchTerm}
  placeholder="Search connections..."
  onClear={() => setSearchTerm("")}
/>
```
