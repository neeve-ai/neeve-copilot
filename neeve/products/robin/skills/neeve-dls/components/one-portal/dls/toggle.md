# Toggle (DLS component)

**Layer:** `@neeve/dls` design system primitive

Binary on/off switch control. Use for feature toggles, view modes, and boolean settings.

## When to use

- Feature toggles (enable/disable)
- View mode switching (compact/expanded)
- Settings toggles
- Boolean form fields
- Configuration flags

## Props

| Prop              | Type                         | Required | Notes                       |
| ----------------- | ---------------------------- | -------- | --------------------------- |
| `checked`         | `boolean`                    | Yes      | Current state               |
| `onCheckedChange` | `(checked: boolean) => void` | Yes      | Callback when toggled       |
| `label`           | `string \| ReactNode`        | No       | Label text                  |
| `disabled`        | `boolean`                    | No       | Disables the toggle         |
| `className`       | `string`                     | No       | Additional Tailwind classes |

## Capabilities

- Binary on/off switch with keyboard navigation (Space to toggle) and click support.
- Integrates seamlessly with React Hook Form's `Controller`.
- Accessible label association via `label` prop or surrounding `<label>`.

## Known limitations

- Not a checkbox (visually/semantically a switch)—don't use for multi-select; use `Checkbox` for that.
- No "loading" or "indeterminate" state—only fully checked or unchecked.
- Label is optional; if omitted, ensure external labeling via `aria-label`.

## Ask before building if:

- Multiple on/off options are needed—use `Checkbox` instead for clarity.
- A loading state is needed while async operation completes—clarify if toggle should be disabled during async, or if separate spinner is needed.

## Accessibility floor

- `label` prop is strongly recommended and auto-associated.
- Keyboard navigation (Space, Tab) is fully supported.
- `disabled` state is properly announced.
- Use `aria-label` if no visible label is provided.

## Example

```tsx
import { Toggle } from "@neeve/dls";
import { useState } from "react";

export function SAMLConfigToggle() {
  const [enabled, setEnabled] = useState(false);

  return (
    <div className="py-dls-300 px-dls-400 flex items-center justify-between rounded-lg border">
      <div>
        <h4>SAML authentication</h4>
        <p className="text-foreground-secondary text-sm">
          Enable single sign-on via SAML
        </p>
      </div>
      <Toggle
        checked={enabled}
        onCheckedChange={setEnabled}
        disabled={!canConfigureSSO}
      />
    </div>
  );
}
```

### Used in one-portal: SAMLConfiguration.tsx

```tsx
<Toggle
  checked={isEnabled}
  onCheckedChange={setIsEnabled}
  label="Enable SAML"
/>
```
