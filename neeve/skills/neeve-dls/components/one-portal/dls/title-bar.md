# TitleBar (DLS component)

**Layer:** `@neeve/dls` design system primitive

Page header with title, subtitle, and optional actions. Use at the top of pages for context and navigation.

## When to use

- Page/section headers
- Breadcrumb navigation context
- Page-level action buttons (Add, Export)
- Section titles with metadata
- List/table view headers

## Props

| Prop         | Type                  | Required | Notes                                |
| ------------ | --------------------- | -------- | ------------------------------------ |
| `title`      | `string \| ReactNode` | Yes      | Main heading text                    |
| `subtitle`   | `string \| ReactNode` | No       | Optional description                 |
| `actions`    | `ReactNode`           | No       | Action buttons/controls (right side) |
| `breadcrumb` | `ReactNode`           | No       | Breadcrumb component                 |
| `className`  | `string`              | No       | Additional Tailwind classes          |

## Capabilities

- Displays page title, optional subtitle, and action buttons in a consistent header bar.
- Supports `Breadcrumb` component placement.
- Responsive layout for actions on mobile/desktop.

## Known limitations

- Does not auto-hide or collapse on mobile—responsive layout must be handled by page-local CSS or wrapper.
- No sticky positioning—if sticky header is needed, add `sticky top-0` CSS via `className`.
- Actions slot is flexible but no built-in spacing between buttons—group buttons with wrapper div and gap classes.

## Ask before building if:

- Sticky header behavior is needed—add CSS, not a component feature.
- Many action buttons will appear—clarify layout, or use `Menubar`/`Menu` to group actions.
- Mobile collapse/drawer is needed—this is page-local responsibility.

## Accessibility floor

- `title` is announced as a heading (semantic `<h1>`).
- `subtitle` is secondary text.
- Action buttons are keyboard-accessible.

## Examples

### Simple page title

```tsx
import { TitleBar } from "@neeve/dls";

export function NodesPage() {
  return (
    <>
      <TitleBar title="Nodes" subtitle="Manage your edge infrastructure" />
      {/* page content */}
    </>
  );
}
```

### With action buttons

```tsx
import { TitleBar, Button } from "@neeve/dls";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faPlus } from "@view/pro-regular-svg-icons";

export function EndpointsPage() {
  return (
    <>
      <TitleBar
        title="Endpoints"
        subtitle="All registered endpoints in your network"
        actions={
          <Button variant="primary" onClick={() => openAddDialog()}>
            <FontAwesomeIcon icon={faPlus} className="mr-dls-200" />
            Add endpoint
          </Button>
        }
      />
      {/* page content */}
    </>
  );
}
```

### Used in one-portal: Title.tsx (Audit page)

```tsx
<TitleBar title="Audit logs" subtitle="All system activities and changes" />
```
