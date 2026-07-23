# Logo (DLS component)

**Layer:** `@neeve/dls` design system primitive

Org or brand logo display. Use in headers and footers for branding.

## When to use

- Page header/footer branding
- Org logo display
- Product identity in navigation

## Props

| Prop        | Type                             | Required | Notes                       |
| ----------- | -------------------------------- | -------- | --------------------------- |
| `src`       | `string`                         | Yes      | Logo image URL              |
| `alt`       | `string`                         | Yes      | Accessibility text          |
| `size`      | `"small" \| "medium" \| "large"` | No       | Logo size                   |
| `className` | `string`                         | No       | Additional Tailwind classes |

## Capabilities

- Displays image asset with three size variants.
- Enforces aspect ratio and responsive sizing.
- Semantic `<img>` element (not CSS background).

## Known limitations

- No link wrapper—if logo should navigate home, wrap component in `<Link>`.
- No blur/lazy loading built-in—for lazy loading, use `next/image` or page-local optimization.
- Alt text is required for accessibility (prop required).

## Ask before building if:

- Logo should link to home—wrap `<Logo>` in `<Link href="/">`.
- Image optimization/lazy loading needed—use `next/image` component instead of `Logo`.
- Custom size variants needed—use `next/image` or custom `<img>` with `className`.

## Accessibility floor

- `alt` prop is required and should be descriptive ("Company logo", "Product name").
- Image is properly sized and respects aspect ratio.

## Example

```tsx
import { Logo } from "@neeve/dls";

export function PageHeader({ logoUrl }: Props) {
  return (
    <header className="gap-dls-400 py-dls-300 px-dls-400 flex items-center border-b">
      <Logo src={logoUrl} alt="Company logo" size="medium" />
      <h1>Dashboard</h1>
    </header>
  );
}
```
