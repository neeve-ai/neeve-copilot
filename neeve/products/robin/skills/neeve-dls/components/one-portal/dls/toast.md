# Toast / ToastV1 (DLS component)

**Layer:** `@neeve/dls` design system primitive

Temporary notification that appears at the bottom corner of the screen. Auto-dismisses after a few seconds.

## When to use

- Operation success messages ("User created successfully")
- Error notifications ("Failed to delete endpoint")
- Async action feedback (file uploaded, saved, etc.)
- Non-blocking notifications that don't require immediate action
- Transient messages that don't need user confirmation

## Props

| Prop           | Type                                          | Required | Notes                                |
| -------------- | --------------------------------------------- | -------- | ------------------------------------ |
| `title`        | `string`                                      | Yes      | Toast heading                        |
| `description`  | `string`                                      | No       | Optional additional context          |
| `type`         | `"success" \| "error" \| "info" \| "warning"` | No       | Notification type; default `"info"`  |
| `duration`     | `number`                                      | No       | Auto-dismiss time (ms); default 5000 |
| `action`       | `ReactNode`                                   | No       | Optional action button               |
| `onOpenChange` | `(open: boolean) => void`                     | No       | Callback when toast closes           |

## Capabilities

- Displays temporary notification at bottom corner with auto-dismiss after duration.
- Supports four notification types with semantic styling (success, error, info, warning).
- Optional action button and close button.
- Auto-dismisses after specified duration (default 5000ms).

## Known limitations

- Does not stack multiple toasts automatically—if multiple toasts are needed, use a toast manager library or page-local state array.
- Duration is a simple auto-dismiss timer—no interaction pause (toast dismisses even if user hovers).
- Toast position is fixed (bottom corner)—no control over placement.

## Ask before building if:

- Multiple toasts need to appear at once—clarify if a toast manager/queue is needed, or if one-portal design specifies single toast at a time.
- Toast should stay open on hover—confirm UX intent; typically toasts auto-dismiss regardless of interaction.
- Custom positioning or styling is needed—this is not supported; build custom component if needed.

## Accessibility floor

- Toast is announced as an alert region.
- `title` and `description` are announced.
- Action button (if provided) is accessible and keyboard-navigable.
- Auto-dismiss does not interrupt screen reader announcement.

## Example

```tsx
import { ToastV1, Button } from "@neeve/dls";
import { useState } from "react";

export function CreateNodeForm() {
  const [toast, setToast] = useState<{
    open: boolean;
    type?: string;
    title?: string;
  }>({
    open: false,
  });

  const handleSubmit = async (data: NodeFormData) => {
    try {
      await createNode(data);
      setToast({
        open: true,
        type: "success",
        title: "Node created successfully",
      });
    } catch (error) {
      setToast({
        open: true,
        type: "error",
        title: "Failed to create node",
      });
    }
  };

  return (
    <>
      <form onSubmit={handleSubmit}>{/* form fields */}</form>

      {toast.open && (
        <ToastV1
          type={toast.type as any}
          title={toast.title || ""}
          onOpenChange={(open) => setToast({ ...toast, open })}
        />
      )}
    </>
  );
}
```

### Used in one-portal: AddNetworkComponent.tsx

```tsx
<ToastV1
  type="error"
  title="Failed to add network"
  description="Please check your settings and try again"
/>
```
