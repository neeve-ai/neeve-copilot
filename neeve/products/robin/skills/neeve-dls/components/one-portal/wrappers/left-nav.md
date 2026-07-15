# LeftNav (Wrapper component)

**Layer:** Wrapper component (`wrappers/components`) — primary sidebar navigation for one-portal application

Vertical navigation toolbar that displays role-based menu items (Workflows, Launch, Analytics, Manage, Profile, Support, Logout). Integrates with Zustand stores for user context, organization context, and access control. Uses DLS Toolbar component with branded organization logo.

## When to use

- Primary app navigation (required in app layout)
- Role-based access control (admin, read_only, access)
- Scope-based menu item visibility (Nodes, Endpoints, Users, Networks, Hierarchy)
- Organization context switching
- User profile and logout access

## Props

No props — component is a self-contained navigation controller that reads all state from Zustand stores.

```tsx
export const LeftNav = () => {...}
```

## Capabilities

- Seven menu items (Workflows, Launch, Analytics, Manage, Profile, Support, Logout).
- Role-based visibility filtering (items only show for authenticated roles).
- Scope-based conditional rendering (e.g., Nodes/Endpoints/Users only appear if user has access).
- Expandable toolbar items with nested menu links.
- Organization logo/initials displayed at top (via branding store).
- Active item detection based on current URL (`usePathname`).
- Access-restricted mode disables all interactive items (shows read-only state).
- Organization switcher dialog modal.
- Support links to external docs and help URLs (respects `CONSTANTS.NEEVE_DOCS_LINK`).
- Logout confirmation prevents accidental double-click.

## Known limitations

- Hardcoded menu structure—not dynamic or configurable at runtime.
- No drag/drop or menu reordering.
- Expandable menu items only show selected item indicator on main item, not nested links.
- Scope checking logic is hardcoded (not fetched from API).
- No breadcrumb or navigation history.

## Ask before building if:

- Dynamic menu items are needed (fetched from API or config)—refactor to accept props.
- Custom menu item ordering per user role—build wrapper with menu builder or settings.
- Nested submenu items need to show as "active"—enhance URL matching logic.
- Different navigation structure for different environments—parameterize via props.

## Accessibility floor

- Navigation is semantic (`<nav>` role; DLS Toolbar handles ARIA attributes).
- Menu items are buttons/links with proper `role="menuitem"`.
- Keyboard navigation fully supported (Tab, Arrow keys, Enter).
- Active item indicated with `aria-current="page"`.
- Disabled/access-restricted items have `aria-disabled="true"`.
- External links have `target="_blank"` with `rel="noopener,noreferrer"`.
- Organization name announced via Avatar `alt` attribute.
- Icon fonts (FontAwesome) properly announce via `<i>` elements with aria-labels.

## Examples

### Basic usage in app layout

```tsx
"use client";

import { LeftNav } from "@/wrappers/components";
import { ReactNode } from "react";

export function AppLayout({ children }: { children: ReactNode }) {
  return (
    <div className="flex h-screen">
      <LeftNav />
      <main className="flex-1 overflow-auto">{children}</main>
    </div>
  );
}

// Used in root layout or page wrapper
export default function DashboardPage() {
  return (
    <AppLayout>
      <div className="p-dls-600">
        <h1>Dashboard</h1>
        {/* page content */}
      </div>
    </AppLayout>
  );
}
```

### In \_layout.tsx

```tsx
import { LeftNav } from "@/wrappers/components";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html>
      <body>
        <div className="flex">
          <LeftNav />
          <main className="flex-1">{children}</main>
        </div>
      </body>
    </html>
  );
}
```

### Access control example

When user role is "read_only", the LeftNav automatically:

- Shows analytics, launch, manage (read-only), and support
- Hides workflow items (admin-only)
- Disables all items if access is restricted (shows spinner, no interaction)

```tsx
// No changes needed—LeftNav handles this internally
<LeftNav />

// User with admin role sees:
// - Workflows (configure nodes)
// - Launch
// - Analytics
// - Manage (nodes, endpoints, users, networks, hierarchy, org settings)
// - Profile
// - Support
// - Logout

// User with read_only role sees (subset):
// - Launch
// - Analytics
// - Manage (read-only view only)
// - Profile
// - Support
// - Logout
```

### Scope-based menu visibility

LeftNav respects user scopes from `useUserScopes()`:

```tsx
// Scopes determine which manage submenu items appear:
// Scope: "Nodes" → Shows /manage/nodes link
// Scope: "Endpoints" → Shows /manage/endpoints link
// Scope: "Users" → Shows /manage/users link
// Scope: "Networks" → Shows /manage/networks link
// Scope: "Hierarchy" → Shows /manage/hierarchy link
// Scope: "All" → Shows all manage items

// No code needed—LeftNav queries scopes from useUserScopes()
<LeftNav />
```

### Organization context integration

LeftNav displays organization branding and allows switching:

```tsx
// Displays:
// 1. Organization logo (from useBrandingStore)
// 2. Organization name (from useCurrentOrgStore)
// 3. "Org Switcher" button to change organization (opens OrgSwitcherDialog)

// All integration is automatic—LeftNav reads from Zustand stores
<LeftNav />

// Organization context available in all child components via stores:
// - useBrandingStore() → brandingSquareLogo, loadingBrandingInfo
// - useCurrentOrgStore() → orgDisplayName, orgId
// - useCurrentUserStore() → user, permissions
```

### Logout flow

```tsx
// Logout button onclick:
// 1. Set logoutClicked flag to prevent double-click
// 2. Redirect to /api/v1/user/current/logout
// 3. Backend clears session and redirects to login

// User click flow:
// Click Logout → setLogoutClicked(true) → window.location.href = "/api/v1/user/current/logout"
// (No client-side state management needed; backend handles session)
```

### Support links

Support menu item expands to show:

- Online help docs (external link to `CONSTANTS.NEEVE_DOCS_LINK`)
- Support contact (external link to `CONSTANTS.NEEVE_SUPPORT_LINK`)
- Terms of service (/terms internal link)
- Build image ID (footer; e.g., "7.2.1-abc123")

```tsx
// All links and text are auto-managed by LeftNav
// Constants used:
// CONSTANTS.NEEVE_DOCS_LINK — documentation site URL
// CONSTANTS.NEEVE_SUPPORT_LINK — support/contact URL

// i18n keys used for all labels (support.tsx uses next-intl):
// workflowsText
// launchText
// analyzeText
// manageText
// nodesText
// endpoints
// users
// networks
// configurehierarchyText
// manage.org.configureOrg
// userprofileText
// support
// onlineHelpDocs
// termsOfService
// (and others)
```

### URL-based active state

```tsx
// LeftNav detects active menu item by comparing pathname to item name
// Example pathname → selected item:
// /workflows/setup-node → "workflows"
// /launch → "launch"
// /manage/nodes → "manage"
// /userprofile → "profile"

// Active item gets `selected={true}` prop sent to DLS Toolbar
// Visual indicator: highlighted background, text color

// Works automatically with Next.js router—no manual prop needed
<LeftNav />
```
