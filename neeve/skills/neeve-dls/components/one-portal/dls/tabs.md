# Tabs (DLS component)

**Layer:** `@neeve/dls` design system primitive

Tabbed interface for switching between related content panels. Use for organizing related information.

## When to use

- Organizing content into logical sections (Info, Settings, Activity)
- Multi-step forms where each step is a tab
- Page-level navigation between related views
- Organizing large data sets

## Props

| Prop          | Type                                                       | Required | Notes                             |
| ------------- | ---------------------------------------------------------- | -------- | --------------------------------- |
| `tabs`        | `Array<{ id: string; label: string; content: ReactNode }>` | Yes      | Tab definitions                   |
| `defaultTab`  | `string`                                                   | No       | Tab id to show initially          |
| `activeTab`   | `string`                                                   | No       | Currently active tab (controlled) |
| `onTabChange` | `(tabId: string) => void`                                  | No       | Callback when tab changes         |
| `className`   | `string`                                                   | No       | Additional Tailwind classes       |

## Capabilities

- Handles tab switching, keyboard navigation (Arrow keys, Tab), and click interactions natively.
- Manages active tab state (controlled or uncontrolled).
- Each tab renders only active content (other tabs are hidden/not in DOM).

## Known limitations

- Does not lazy-load tab content—all tab content exists in DOM, just hidden.
- No scroll handling for many tabs—if 10+ tabs, wrapping/scrollable tab bar may be needed (page-local layout).
- Not suitable for step-by-step wizards where validation between steps is required—use a custom multi-step form component instead.

## Ask before building if:

- More than 10 tabs are needed—clarify if this is the right UX, or if filtering/collapsing is better.
- Validation is needed between tab transitions ("prevent moving to next tab until this field is valid")—this requires custom page-local logic; `Tabs` component doesn't support it.
- Lazy loading of tab content is needed for performance—this requires custom implementation.

## Accessibility floor

- Tab labels are announced with their active/inactive state.
- Keyboard navigation (Arrow keys, Tab) is fully supported.
- `activeTab` state is managed and announced.

## Examples

### Simple tabs

```tsx
import { Tabs } from "@neeve/dls";
import { useState } from "react";

export function UserDetailTabs({ userId }: { userId: string }) {
  const [activeTab, setActiveTab] = useState("info");

  return (
    <Tabs
      tabs={[
        {
          id: "info",
          label: "Information",
          content: <UserInfo userId={userId} />,
        },
        {
          id: "permissions",
          label: "Permissions",
          content: <UserPermissions userId={userId} />,
        },
        {
          id: "activity",
          label: "Activity",
          content: <UserActivity userId={userId} />,
        },
      ]}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    />
  );
}
```

### Uncontrolled tabs with default

```tsx
import { Tabs } from "@neeve/dls";

export function NodeDetailTabs({ nodeId }: { nodeId: string }) {
  return (
    <Tabs
      defaultTab="status"
      tabs={[
        {
          id: "status",
          label: "Status",
          content: <NodeStatus nodeId={nodeId} />,
        },
        {
          id: "config",
          label: "Configuration",
          content: <NodeConfig nodeId={nodeId} />,
        },
        {
          id: "logs",
          label: "Logs",
          content: <NodeLogs nodeId={nodeId} />,
        },
      ]}
    />
  );
}
```

### Used in one-portal: UserInfoTabs.tsx

```tsx
<Tabs
  activeTab={activeTab}
  onTabChange={setActiveTab}
  tabs={[
    {
      id: "info",
      label: "User Information",
      content: <UserInfo />,
    },
    {
      id: "permissions",
      label: "Permissions",
      content: <UserPermissions />,
    },
  ]}
/>
```
