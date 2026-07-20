# Dialog / DialogRaw (DLS component)

**Layer:** `@neeve/dls` design system primitive

Modal overlay with header, content, and footer sections. Use for confirmation prompts, forms, and focused task flows.

## When to use

- Confirmation dialogs ("Are you sure?")
- Multi-step forms or wizards in a modal
- Focused data entry tasks (add user, edit endpoint)
- Alerts that require explicit user action

## Props

`Dialog` is a wrapper component that provides common dialog structure. `DialogRaw` gives you full control.

| Component | Prop           | Type                             | Required | Notes                                 |
| --------- | -------------- | -------------------------------- | -------- | ------------------------------------- |
| `Dialog`  | `open`         | `boolean`                        | Yes      | Controls open/close state             |
|           | `onOpenChange` | `(open: boolean) => void`        | Yes      | Callback when user closes             |
|           | `title`        | `string`                         | No       | Header text                           |
|           | `description`  | `string \| ReactNode`            | No       | Body content                          |
|           | `children`     | `ReactNode`                      | No       | Custom body (overrides `description`) |
|           | `footer`       | `ReactNode`                      | No       | Footer actions (buttons)              |
|           | `isLoading`    | `boolean`                        | No       | Shows spinner, disables actions       |
|           | `size`         | `"small" \| "medium" \| "large"` | No       | Dialog width; default `"medium"`      |

## Capabilities

- Handles open/close state, backdrop click handling, and focus management natively.
- Modal overlay that blocks interaction with page content behind it.
- Supports header (title + description), body (custom children), and footer (buttons/actions).
- Integrates with async operations via `isLoading` (disables actions, shows spinner).
- **Supports dynamic content**: title, description, children, and footer can be updated based on page-local state, enabling wizards, multi-step flows, and context-switching dialogs without stacking multiple dialogs.

## Known limitations

- **Multiple dialogs cannot be open at the same time** — one-portal pattern uses a single dialog with dynamic content (title, children, footer) that changes based on state; this is the recommended approach for multi-step or context-switching flows.
- Does not provide automatic form validation—pair with React Hook Form + Zod for validation.
- No built-in animation configuration—uses Radix/system defaults.
- Does not auto-close after an async action completes—page-local code must call `onOpenChange(false)` after the operation finishes.

## Ask before building if:

- Form submission should auto-close the dialog—this requires page-local coordination between the form submission logic and `onOpenChange(false)`.
- A multi-step flow is needed (e.g., "Choose action" → "Confirm" → "Success")—**use a single dialog with state-based content switching** (see "Dynamic dialog content" example below), not multiple stacked dialogs.

## Accessibility floor

- `title` and `description` are announced when dialog opens.
- Focus is moved to the dialog on open; backdrop click and Escape key close it.
- Footer buttons must have clear accessible names ("Delete", "Cancel", not just icons).

## Examples

### Simple confirmation dialog

```tsx
import { Dialog, Button } from "@neeve/dls";
import { useState } from "react";

export function DeleteNodeDialog({
  nodeName,
  onConfirm,
}: {
  nodeName: string;
  onConfirm: () => void;
}) {
  const [open, setOpen] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  const handleDelete = async () => {
    setIsDeleting(true);
    await onConfirm();
    setIsDeleting(false);
    setOpen(false);
  };

  return (
    <Dialog
      open={open}
      onOpenChange={setOpen}
      title="Delete node?"
      description={`Are you sure you want to delete "${nodeName}"? This cannot be undone.`}
      isLoading={isDeleting}
      footer={
        <div className="gap-dls-200 flex justify-end">
          <Button variant="secondary" onClick={() => setOpen(false)}>
            Cancel
          </Button>
          <Button variant="primary" onClick={handleDelete}>
            Delete
          </Button>
        </div>
      }
    />
  );
}
```

### Form inside dialog

```tsx
import { Dialog, Button, TextInput } from "@neeve/dls";
import { useForm, Controller } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

const schema = z.object({
  name: z.string().min(1, "Name is required"),
  email: z.string().email("Invalid email"),
});

type FormData = z.infer<typeof schema>;

export function AddUserDialog({ open, onOpenChange, onSubmit }: Props) {
  const { control, handleSubmit } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  return (
    <Dialog
      open={open}
      onOpenChange={onOpenChange}
      title="Add new user"
      size="medium"
      footer={
        <div className="gap-dls-200 flex justify-end">
          <Button variant="secondary" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button variant="primary" onClick={handleSubmit(onSubmit)}>
            Create user
          </Button>
        </div>
      }
    >
      <form className="gap-dls-400 flex flex-col">
        <Controller
          name="name"
          control={control}
          render={({ field, fieldState: { error } }) => (
            <TextInput label="Name" {...field} error={error?.message} />
          )}
        />
        <Controller
          name="email"
          control={control}
          render={({ field, fieldState: { error } }) => (
            <TextInput
              label="Email"
              type="email"
              {...field}
              error={error?.message}
            />
          )}
        />
      </form>
    </Dialog>
  );
}
```

### Dynamic dialog content (recommended one-portal pattern)

Use a single dialog with state-managed content for multi-step flows or context-switching scenarios.

```tsx
import { Dialog, Button, TextInput } from "@neeve/dls";
import { useState } from "react";

type DialogStep = "action-choice" | "confirm" | "success";

export function MultiStepActionDialog({
  resourceName,
  onExecute,
}: {
  resourceName: string;
  onExecute: (action: string) => Promise<void>;
}) {
  const [open, setOpen] = useState(false);
  const [step, setStep] = useState<DialogStep>("action-choice");
  const [isLoading, setIsLoading] = useState(false);
  const [selectedAction, setSelectedAction] = useState<string>("");

  const handleExecute = async () => {
    setIsLoading(true);
    try {
      await onExecute(selectedAction);
      setStep("success");
    } finally {
      setIsLoading(false);
    }
  };

  const handleClose = () => {
    setOpen(false);
    // Reset to initial state when dialog closes
    setTimeout(() => setStep("action-choice"), 300);
  };

  // Dynamically set dialog props based on current step
  const getDialogProps = () => {
    switch (step) {
      case "action-choice":
        return {
          title: `What would you like to do?`,
          description: `Choose an action for "${resourceName}"`,
          footer: (
            <div className="gap-dls-200 flex justify-end">
              <Button variant="secondary" onClick={handleClose}>
                Cancel
              </Button>
              <Button
                variant="primary"
                disabled={!selectedAction}
                onClick={() => setStep("confirm")}
              >
                Next
              </Button>
            </div>
          ),
        };
      case "confirm":
        return {
          title: `Confirm ${selectedAction}`,
          description: `Are you sure you want to ${selectedAction.toLowerCase()} "${resourceName}"? This cannot be undone.`,
          footer: (
            <div className="gap-dls-200 flex justify-end">
              <Button
                variant="secondary"
                onClick={() => setStep("action-choice")}
              >
                Back
              </Button>
              <Button
                variant="primary"
                isLoading={isLoading}
                onClick={handleExecute}
              >
                Confirm
              </Button>
            </div>
          ),
        };
      case "success":
        return {
          title: `${selectedAction} successful`,
          description: `"${resourceName}" has been ${selectedAction.toLowerCase()}.`,
          footer: (
            <div className="gap-dls-200 flex justify-end">
              <Button variant="primary" onClick={handleClose}>
                Done
              </Button>
            </div>
          ),
        };
    }
  };

  const dialogProps = getDialogProps();

  return (
    <>
      <Button onClick={() => setOpen(true)}>Manage {resourceName}</Button>

      <Dialog
        open={open}
        onOpenChange={handleClose}
        title={dialogProps.title}
        description={dialogProps.description}
        isLoading={isLoading}
        footer={dialogProps.footer}
        size="medium"
      >
        {step === "action-choice" && (
          <div className="gap-dls-300 flex flex-col">
            {["Archive", "Delete", "Transfer"].map((action) => (
              <label
                key={action}
                className="gap-dls-200 p-dls-300 hover:bg-dls-200 flex cursor-pointer items-center rounded border"
              >
                <input
                  type="radio"
                  name="action"
                  value={action}
                  checked={selectedAction === action}
                  onChange={(e) => setSelectedAction(e.target.value)}
                  className="cursor-pointer"
                />
                <span className="flex-1">{action}</span>
              </label>
            ))}
          </div>
        )}
      </Dialog>
    </>
  );
}
```

### Used in one-portal: AddUserDialog.tsx

```tsx
<Dialog
  open={openAddUserDialog}
  onOpenChange={setOpenAddUserDialog}
  title="Add new user"
  footer={
    <div className="gap-dls-200 flex justify-end">
      <Button variant="secondary" onClick={() => setOpenAddUserDialog(false)}>
        Cancel
      </Button>
      <Button variant="primary" onClick={handleCreateUser}>
        Create
      </Button>
    </div>
  }
>
  <AddUserForm ref={addUserFormRef} />
</Dialog>
```
