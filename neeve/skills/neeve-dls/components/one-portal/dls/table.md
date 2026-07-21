# Table (DLS — internal primitive, do not use directly)

> **Do not use this component directly in one-portal.**
> Always use [`TableV2`](../wrappers/table-v2.md) instead — for every table, including
> static ones. `TableV2` is the only sanctioned table surface in one-portal.
>
> This file is kept as an internal reference because `TableV2` is built on top of
> `Table`. It is not an option in `components/INDEX.md` and should never appear in
> product code as a direct import.

---

If you arrived here from a user request, stop and redirect to
[`components/wrappers/table-v2.md`](../wrappers/table-v2.md).

## Props

`Table` accepts standard HTML `<table>` attributes plus two custom props:

| Prop                    | Type                        | Required | Default | Notes                                                                                                                                                        |
| ----------------------- | --------------------------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `containerRef`          | `React.Ref<HTMLDivElement>` | No       | —       | Ref forwarded to the outer scroll container div rather than the `<table>` element itself. Useful when the consumer needs to measure or scroll the container. |
| `horizontalWheelScroll` | `boolean`                   | No       | —       | When `true`, vertical wheel events are converted to horizontal scroll on the container. Useful for wide tables without a trackpad.                           |

All other standard HTML `<table>` attributes pass through. There is no custom
data/columns API — you compose the JSX by hand (map over rows yourself).

`TableHeader`, `TableBody`, `TableRow`, `TableHead`, `TableCell` pass through their
respective standard HTML element attributes only.

`TableFooter` accepts `children: ReactNode` and an optional `className: string`.

## Capabilities

- Correct DLS spacing, borders, and typography for header/body/footer cells.
- `TableRow` applies a bottom border (`dls-border-b`) and a CSS transition on color changes.
- No zebra striping in the component itself — add via `className` on `TableRow` if the design requires it.

## Known limitations

- No sorting, filtering, pagination, column resize/reorder/hide, or row
  selection — do not add these directly to a page using the bare `Table`; that logic
  belongs in `TableV2`.
- No virtualization — not suitable for large datasets on its own.

## Example (only for genuinely static tables)

```tsx
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from "@neeve/dls";

<Table>
  <TableHeader>
    <TableRow>
      <TableHead>Name</TableHead>
      <TableHead>Status</TableHead>
    </TableRow>
  </TableHeader>
  <TableBody>
    {rows.map((r) => (
      <TableRow key={r.id}>
        <TableCell>{r.name}</TableCell>
        <TableCell>{r.status}</TableCell>
      </TableRow>
    ))}
  </TableBody>
</Table>;
```
