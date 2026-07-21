# LoadingButton (Wrapper component)

**Layer:** Wrapper component (`wrappers/components`) — builds on DLS `Button` with loading state management

Button component that handles pending/loading states with automatic disabling and dynamic text. Ideal for form submissions and async operations.

## When to use

- Form submit buttons during async operations (mutations, API calls)
- Any button where you need to prevent double-clicks during processing
- Submit actions where you want to show feedback to the user
- Combined with Tanstack Query `useMutation` or similar async handlers

## Props

| Prop             | Type                                             | Required | Notes                                                           |
| ---------------- | ------------------------------------------------ | -------- | --------------------------------------------------------------- |
| `loading`        | `boolean`                                        | No       | When true, shows loader and displays loadingText                |
| `text`           | `string`                                         | Yes      | Button label when not loading                                   |
| `loadingText`    | `string`                                         | No       | Text shown during loading; defaults to i18n "manage.org.saving" |
| `disabled`       | `boolean`                                        | No       | Additional disabled state (combined with loading state)         |
| `...buttonProps` | `ComponentProps<typeof Button>` (minus children) | No       | All other DLS Button props (variant, size, onClick, etc.)       |

## Capabilities

- Automatically disables button when `loading=true` or `disabled=true` (OR logic).
- Displays loader spinner via DLS Button's `showLoader` prop.
- Swaps button text between `text` and `loadingText` based on loading state.
- Falls back to i18n key "manage.org.saving" if `loadingText` not provided.
- Forwards all standard Button props (variant, size, className, onClick, etc.).
- Integrates seamlessly with Tanstack Query and React Hook Form.

## Known limitations

- Only manages visual loading state—does not handle the async operation itself.
- Single loading state only—no multi-step or progress indicators.
- Text cannot include JSX elements (must be string only).
- Disabling logic uses OR (button disabled if `loading || disabled`)—not customizable.

## Ask before building if:

- Multiple async states needed (e.g., error, success states)—build wrapper or use state machine pattern.
- Button text must include React elements (icons, badges)—use DLS Button directly with manual state logic.
- Different behavior needed for `loading` vs `disabled` (e.g., loading but enabled)—pass DLS Button directly.

## Accessibility floor

- Button is semantic (native `<button>` from DLS).
- Disabled state is announced (`disabled` attribute set).
- Loader spinner is announced via `aria-busy` (handled by DLS Button).
- Button remains keyboard accessible when not loading.
- Loading text is announced when state changes.

## Examples

### Basic form submit

```tsx
import { LoadingButton } from "@/wrappers/components";
import { useState } from "react";

export function AddEndpointForm() {
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await api.addEndpoint(formData);
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input type="text" placeholder="Endpoint name" />
      <LoadingButton
        loading={loading}
        text="Add Endpoint"
        onClick={handleSubmit}
      />
    </form>
  );
}
```

### With Tanstack Query mutation

```tsx
import { LoadingButton } from "@/wrappers/components";
import { useMutation } from "@tanstack/react-query";

export function CreateNodeButton() {
  const mutation = useMutation({
    mutationFn: (data) => api.createNode(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["nodes"] });
    },
  });

  return (
    <LoadingButton
      loading={mutation.isPending}
      text="Create Node"
      loadingText="Creating..."
      onClick={() => mutation.mutate({ name: "Node 1" })}
    />
  );
}
```

### With form validation

```tsx
import { LoadingButton } from "@/wrappers/components";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";

export function EditOrgForm() {
  const { handleSubmit, formState, watch } = useForm({
    resolver: zodResolver(orgSchema),
  });

  const [isSaving, setIsSaving] = useState(false);
  const formData = watch();
  const isFormValid = formState.isValid;

  const onSubmit = async (data: OrgFormData) => {
    setIsSaving(true);
    try {
      await api.updateOrg(data);
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      {/* form fields */}
      <LoadingButton
        loading={isSaving}
        text="Save Organization"
        loadingText="Saving..."
        disabled={!isFormValid}
        onClick={handleSubmit(onSubmit)}
        variant="primary"
      />
    </form>
  );
}
```

### With custom loading text

```tsx
import { LoadingButton } from "@/wrappers/components";
import { useMutation } from "@tanstack/react-query";

export function DeployButton({ deploymentId }: { deploymentId: string }) {
  const mutation = useMutation({
    mutationFn: () => api.deployNode(deploymentId),
  });

  return (
    <LoadingButton
      loading={mutation.isPending}
      text="Deploy Now"
      loadingText="Deploying... (may take 2-3 min)"
      onClick={() => mutation.mutate()}
      variant="primary"
      size="large"
    />
  );
}
```

### Multiple buttons with shared loading state

```tsx
import { LoadingButton } from "@/wrappers/components";
import { Button } from "@neeve/dls";

export function DeleteConfirmDialog({ itemId }: { itemId: string }) {
  const [loading, setLoading] = useState(false);

  const handleDelete = async () => {
    setLoading(true);
    try {
      await api.deleteItem(itemId);
      onClose();
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="gap-dls-300 flex">
      <Button variant="secondary" disabled={loading} onClick={onClose}>
        Cancel
      </Button>
      <LoadingButton
        loading={loading}
        text="Delete"
        loadingText="Deleting..."
        onClick={handleDelete}
        variant="destructive"
      />
    </div>
  );
}
```
