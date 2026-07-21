# AlertBanner (DLS component)

**Layer:** `@neeve/dls` design system primitive

Dismissible inline alert message. Used for status updates, warnings, and info messages that appear within page content.

## When to use

- Inline warnings ("This action will delete 50 endpoints")
- Status messages within forms or dialogs
- Info callouts that need to be dismissible
- Validation errors or constraint messages

## Props

| Prop          | Type                                          | Required | Notes                                |
| ------------- | --------------------------------------------- | -------- | ------------------------------------ |
| `type`        | `"info" \| "warning" \| "error" \| "success"` | Yes      | Visual style and icon                |
| `title`       | `string`                                      | No       | Bold heading (optional)              |
| `description` | `string \| ReactNode`                         | No       | Main message content                 |
| `onDismiss`   | `() => void`                                  | No       | Callback when user closes the banner |
| `className`   | `string`                                      | No       | Additional Tailwind classes          |

## Capabilities

- Displays inline warning/error/info/success messages with semantic styling.
- Supports dismissible state via `onDismiss` callback.
- Integrates with page layout inline (not modal/overlay).

## Known limitations

- Not a toast (temporary, auto-dismiss)—use `Toast`/`ToastV1` for that.
- Not for modal confirmation dialogs—use `Dialog` for that.
- Does not auto-dismiss—if temporary display is needed, page-local code must call `onDismiss` after a timeout.
- No rich content (links, formatted text)—keep text simple or wrap text in `<a>` within `description` if needed.

## Ask before building if:

- The message should auto-dismiss—clarify if this should be a `Toast` instead, or if page-local setTimeout is acceptable.
- Rich HTML or interactive content is needed in the message—confirm scope with designer; typically keep `AlertBanner` text-only.
- Multiple alerts need to stack—clarify if this is a list of validation errors (multiple `AlertBanner` in a form) or a toast-like notification stack.

## Accessibility floor

- `type` determines the semantic role (error, warning, info, success).
- `title` and `description` are announced.
- Dismiss button has accessible name.

## Examples

### Warning before destructive action

```tsx
import { AlertBanner, Button } from "@neeve/dls";

export function DeleteEndpointsWarning({ count }: { count: number }) {
  const [dismissed, setDismissed] = useState(false);

  if (dismissed) return null;

  return (
    <AlertBanner
      type="warning"
      title="Permanent deletion"
      description={`You are about to delete ${count} endpoints. This action cannot be undone.`}
      onDismiss={() => setDismissed(true)}
    />
  );
}
```

### Info message with HTML content

```tsx
import { AlertBanner } from "@neeve/dls";

export function MigrationInfo() {
  return (
    <AlertBanner
      type="info"
      title="Network migration in progress"
      description="Your network topology is being updated. New endpoints will appear within 5 minutes."
    />
  );
}
```

### Used in one-portal: ConnectToInternet.tsx

```tsx
<AlertBanner
  type="error"
  title="Connection failed"
  description="Could not establish internet connection. Please check network settings."
  onDismiss={handleDismiss}
/>
```
