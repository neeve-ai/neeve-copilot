# StepperTabs (Standalone component)

**Layer:** Wrapper component (`standalones/components`) — multi-step progress indicator with numbered steps

Visual progress tracker for multi-step workflows, forms, or wizards. Displays numbered steps, completed states, and disabled steps with interactive tab switching.

## When to use

- Multi-step forms (Step 1 → 2 → 3)
- Wizard workflows (Setup → Configuration → Review)
- Progress tracking in modal dialogs
- Step-by-step guided processes
- Form validation with forward-only progression

## Props

| Prop          | Type                      | Required | Notes                                           |
| ------------- | ------------------------- | -------- | ----------------------------------------------- |
| `tabs`        | `StepperTabItem[]`        | Yes      | Array of step definitions                       |
| `activeTab`   | `number`                  | No       | Controlled active step (1-based index)          |
| `defaultTab`  | `number`                  | No       | Initial active step for uncontrolled; default 1 |
| `onTabChange` | `(index: number) => void` | No       | Callback when step changes                      |
| `className`   | `string`                  | No       | Additional Tailwind classes                     |

### StepperTabItem

| Property   | Type      | Required | Notes                            |
| ---------- | --------- | -------- | -------------------------------- |
| `title`    | `string`  | Yes      | Step label text                  |
| `disabled` | `boolean` | No       | Disable this step (cannot click) |

## Capabilities

- Numbered step circles (1, 2, 3...) with visual indicators for active/completed/disabled states.
- Completed steps show a checkmark icon instead of number.
- Keyboard navigation (Tab, Arrow keys within step list, Enter to select).
- Controlled and uncontrolled modes via `activeTab` and `defaultTab`.
- Step titles displayed below each step number.
- Disabled steps cannot be clicked (visual opacity reduction).
- Connecting line between steps (CSS-based).

## Known limitations

- No automatic step progression or form validation—page-local code must control activeTab and determine when to enable next step.
- Cannot go backwards to disabled steps—once disabled, step is unclickable.
- No multi-line step titles; long titles may overflow—keep titles concise (1-2 words).
- Line connector between steps is visual only; not customizable.

## Ask before building if:

- Automatic form validation and step progression needed—implement page-local validation logic and conditionally disable next step.
- Backwards navigation should be prevented programmatically—add `onTabChange` handler to validate forward-only flow.
- Custom step icons or styling needed—extend component or build custom stepper.

## Accessibility floor

- Each step is a `<button>` with `role="tab"` and `aria-selected`.
- Current step has `aria-current="step"`.
- Disabled steps have `disabled` attribute and reduced opacity.
- Keyboard navigation (Tab, Arrow keys) fully supported.
- Step labels are announced.
- Checkmark icon is semantic (no alt text needed; icon conveys completion visually).

## Examples

### Basic uncontrolled stepper

```tsx
import { StepperTabs, type StepperTabItem } from "@/standalones/components";
import { useState } from "react";

export function MultiStepForm() {
  const [currentStep, setCurrentStep] = useState(1);

  const steps: StepperTabItem[] = [
    { title: "Details" },
    { title: "Settings" },
    { title: "Review" },
  ];

  return (
    <div className="gap-dls-600 flex flex-col">
      <StepperTabs tabs={steps} defaultTab={1} onTabChange={setCurrentStep} />

      {currentStep === 1 && <DetailsForm />}
      {currentStep === 2 && <SettingsForm />}
      {currentStep === 3 && <ReviewForm />}
    </div>
  );
}
```

### Controlled stepper with validation

```tsx
import { StepperTabs, type StepperTabItem } from "@/standalones/components";
import { useState } from "react";

export function ValidatedWizard() {
  const [currentStep, setCurrentStep] = useState(1);
  const [isStep1Valid, setIsStep1Valid] = useState(false);
  const [isStep2Valid, setIsStep2Valid] = useState(false);

  const steps: StepperTabItem[] = [
    { title: "Account" },
    { title: "Profile", disabled: !isStep1Valid },
    { title: "Confirm", disabled: !isStep2Valid },
  ];

  const handleStepChange = (step: number) => {
    // Only allow forward progression if current step is valid
    if (step > currentStep && currentStep === 1 && !isStep1Valid) {
      alert("Please complete this step first");
      return;
    }
    setCurrentStep(step);
  };

  return (
    <div>
      <StepperTabs
        tabs={steps}
        activeTab={currentStep}
        onTabChange={handleStepChange}
      />

      {currentStep === 1 && <AccountForm onValidChange={setIsStep1Valid} />}
      {currentStep === 2 && <ProfileForm onValidChange={setIsStep2Valid} />}
      {currentStep === 3 && <ConfirmForm />}
    </div>
  );
}
```

### In a modal dialog

```tsx
import { StepperTabs, type StepperTabItem } from "@/standalones/components";
import { Dialog, Button } from "@neeve/dls";
import { useState } from "react";

export function SetupWizardDialog() {
  const [open, setOpen] = useState(false);
  const [currentStep, setCurrentStep] = useState(1);

  const steps: StepperTabItem[] = [
    { title: "Connect" },
    { title: "Configure" },
    { title: "Complete" },
  ];

  const handleNext = () => {
    if (currentStep < steps.length) setCurrentStep(currentStep + 1);
  };

  const handleBack = () => {
    if (currentStep > 1) setCurrentStep(currentStep - 1);
  };

  return (
    <>
      <Button onClick={() => setOpen(true)}>Start Setup</Button>

      <Dialog
        open={open}
        onOpenChange={setOpen}
        title="Setup Wizard"
        size="medium"
        footer={
          <div className="gap-dls-200 flex justify-between">
            <Button
              variant="secondary"
              onClick={handleBack}
              disabled={currentStep === 1}
            >
              Back
            </Button>
            <Button
              variant="primary"
              onClick={handleNext}
              disabled={currentStep === steps.length}
            >
              {currentStep === steps.length ? "Finish" : "Next"}
            </Button>
          </div>
        }
      >
        <StepperTabs
          tabs={steps}
          activeTab={currentStep}
          onTabChange={setCurrentStep}
        />

        {currentStep === 1 && <ConnectionStep />}
        {currentStep === 2 && <ConfigurationStep />}
        {currentStep === 3 && <CompleteStep />}
      </Dialog>
    </>
  );
}
```

### With mixed enabled/disabled steps

```tsx
import { StepperTabs, type StepperTabItem } from "@/standalones/components";
import { useState } from "react";

export function RestrictedWizard() {
  const [currentStep, setCurrentStep] = useState(1);

  // Only steps 1 and 2 are accessible; step 3 is locked
  const steps: StepperTabItem[] = [
    { title: "Basic" },
    { title: "Advanced" },
    { title: "Premium", disabled: true }, // Requires subscription
  ];

  return (
    <div>
      <StepperTabs
        tabs={steps}
        activeTab={currentStep}
        onTabChange={setCurrentStep}
      />

      <div className="p-dls-400">
        {currentStep === 1 && <p>Basic features</p>}
        {currentStep === 2 && <p>Advanced settings</p>}
      </div>

      <div className="mt-dls-400 p-dls-300 rounded-lg bg-background-secondary">
        <p className="text-foreground-secondary text-sm">
          Step 3 is locked. Upgrade to access premium settings.
        </p>
      </div>
    </div>
  );
}
```
