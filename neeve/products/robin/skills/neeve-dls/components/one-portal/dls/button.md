# Button (DLS)

**Layer:** `@neeve/dls` — import `{ Button }` (and `buttonVariants` /
`iconOnlyButtonVariants` if you need the class strings directly, e.g. to style a link
as a button).

## When to use

Any primary interactive action: form submission, triggering a dialog, navigation
styled as an action, destructive actions (delete, remove). For icon-only actions
(e.g. a toolbar icon button), use the same `Button` without `children` and with an
`icon` prop rather than a bare `<button>` with custom padding.

## Props

| Prop            | Type                                        | Required                      | Default     | Notes                                                                                                                                                           |
| --------------- | ------------------------------------------- | ----------------------------- | ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `variant`       | `"primary" \| "secondary" \| "ghost"`       | No                            | `"primary"` | Ask if the request implies a variant not stated. For destructive actions (delete, remove) use `"secondary"` or `"ghost"` and pair with a `Dialog` confirm step. |
| `size`          | `"small" \| "large"`                        | No                            | `"large"`   |                                                                                                                                                                 |
| `disabled`      | `boolean`                                   | No                            | `false`     | Inherited from `React.ButtonHTMLAttributes`.                                                                                                                    |
| `showLoader`    | `boolean`                                   | No                            | `false`     | Replaces children with a spinner. Use instead of manually swapping in a `Loader` inside the button.                                                             |
| `icon`          | `IconProp \| IconDefinition \| JSX.Element` | No                            | —           | Provide `icon` without `children` to enter icon-only mode; provide alongside `children` for icon+label.                                                         |
| `iconPlacement` | `"leading" \| "trailing"`                   | No                            | `"leading"` | Only relevant when `icon` and `children` are both provided.                                                                                                     |
| `asChild`       | `boolean`                                   | No                            | `false`     | Renders as the child element via Radix `Slot` — useful for styling a `<Link>` as a button.                                                                      |
| `width`         | `string \| number`                          | No                            | —           | Inline style override for button width.                                                                                                                         |
| `height`        | `string \| number`                          | No                            | —           | Inline style override for button height.                                                                                                                        |
| `onClick`       | `(e) => void`                               | Yes (for interactive buttons) | —           | Inherited from `React.ButtonHTMLAttributes`.                                                                                                                    |
| `children`      | `ReactNode`                                 | Yes (unless icon-only mode)   | —           | Button label. Omit entirely (along with providing `icon`) to activate icon-only mode.                                                                           |

### Icon-only mode

Icon-only mode is **implicit**: provide `icon` with no `children` (and `showLoader`
not set). The component automatically switches to `iconOnlyButtonVariants` styling,
which has its own default variant of `"ghost"` (different from the regular button
default of `"primary"`). Always supply `aria-label` in this case.

## Capabilities

- Handles focus ring, hover/active/disabled visual states, and loading state natively.
- Icon + label combinations (leading/trailing icon) are supported via `icon` + `iconPlacement`.
- Can render as any element (e.g. `<a>`, Next.js `<Link>`) via `asChild`.

## Known limitations

- No built-in confirmation step for destructive actions — pair with `Dialog` if the
  action needs a confirm step; don't build a custom confirm affordance into the button
  itself.
- Not a dropdown trigger by itself — pair with `Menu`/`Popover` for button-triggered
  menus rather than adding menu logic to `Button`.

## Ask before building if:

- The request says "button" without a variant and the action's intent isn't obvious
  from context (is this primary on the page, or a secondary/tertiary action?).
- It's icon-only and no accessible label has been given.

## Accessibility floor

- In icon-only mode (`icon` provided, no `children`), an `aria-label` describing the
  action is required — always ask for or infer one, never ship an icon button with no
  accessible name.
- `disabled` buttons should not also carry `onClick` handlers that fire (the component
  handles this, but don't work around it with custom pointer-events CSS).

## Example

```tsx
import { Button } from "@neeve/dls";

// Primary action
<Button variant="primary" size="large" onClick={handleSave}>
  Save changes
</Button>

// Secondary action with leading icon
<Button variant="secondary" size="small" icon={faTrash} onClick={handleDelete}>
  Delete workspace
</Button>

// Icon-only (ghost, implicit icon-only mode — must have aria-label)
<Button icon={faXmark} aria-label="Close panel" onClick={onClose} />

// Render as a Next.js Link styled as a button
<Button asChild variant="primary">
  <Link href="/settings">Go to settings</Link>
</Button>
```
