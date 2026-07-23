# Breadcrumb (DLS component)

**Layer:** `@neeve/dls` design system primitive

Hierarchical navigation path showing current location. Use in page headers for context and navigation.

## When to use

- Detail page navigation (Endpoints > Endpoint 1)
- Hierarchical views (Org > Portfolio > Site)
- Pages nested multiple levels deep
- Providing back-navigation context

## Props

| Prop        | Type                                                            | Required | Notes                                |
| ----------- | --------------------------------------------------------------- | -------- | ------------------------------------ |
| `items`     | `Array<{ label: string; href?: string; onClick?: () => void }>` | Yes      | Breadcrumb segments                  |
| `separator` | `string \| ReactNode`                                           | No       | Separator between items; default `/` |
| `className` | `string`                                                        | No       | Additional Tailwind classes          |

## Capabilities

- Displays hierarchical navigation path with separators.
- Supports both `href` (for Next.js `<Link>` integration) and `onClick` handlers per item.
- Current page (last item) typically has no link.

## Known limitations

- Does not auto-truncate long paths—if many levels, design must address truncation/overflow.
- Does not show "active" state styling automatically—page-local code or designer must style current page.
- Separator is not customizable beyond simple string/ReactNode.

## Ask before building if:

- Many breadcrumb levels (5+) will appear—confirm if truncation ("..." middle items) is needed.
- Custom separator or styling is needed beyond default—use page-local wrapper or custom component.

## Accessibility floor

- Breadcrumb is announced as navigation landmark.
- Each item is a link (if `href` provided) or span (if current page).
- Separators are decorative (no accessibility impact).

## Example

```tsx
import { Breadcrumb } from "@neeve/dls";
import Link from "next/link";

export function EndpointDetailHeader({ endpointId, siteName }: Props) {
  return (
    <Breadcrumb
      items={[
        { label: "Home", href: "/" },
        { label: "Endpoints", href: "/manage/endpoints" },
        { label: siteName, href: `/manage/hierarchy/site/${siteId}` },
        { label: "Detail" }, // current page, no link
      ]}
    />
  );
}
```
