# One Portal — Coding Standards

Reference for AI-generated code in `one-portal`. All generated code **must** conform
to these conventions so it is indistinguishable from hand-written one-portal code and
can be merged without a style pass.

---

## Tech Stack

| Layer         | Technology                                    | Notes for AI                                                                                     |
| ------------- | --------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Framework     | Next.js 14.2 App Router                       | `output: "standalone"`, `force-dynamic` root layout                                              |
| Language      | TypeScript 5                                  | `strict: false`, `strictNullChecks: false` — **do not** add strict-null workarounds              |
| UI runtime    | React 18.3                                    | `reactStrictMode: false`; client-component heavy                                                 |
| Styling       | Tailwind CSS 3.4 + `tailwind-merge` + `clsx`  | Always compose via `cn()` helper, never string concat                                            |
| Design system | `@neeve/dls`                                  | DLS tokens use `dls-*` prefix classes and CSS custom properties                                  |
| Icons         | FontAwesome Pro                               | `@view/pro-regular-svg-icons`, `@view/pro-solid-svg-icons`; FA kit is globally loaded            |
| Server state  | TanStack Query v5                             | All data fetching goes through query hooks — no direct service calls from components             |
| HTTP          | axios 1.7                                     | Two instances: One API and SecureEdge proxy — both wrapped inside service classes                |
| Client state  | Zustand v5                                    | 13 stores under `shared/store/` — never create new component-level context for cross-route state |
| Forms         | react-hook-form 7 + `@hookform/resolvers/zod` | Always `zodResolver`; never raw `useState` chains for forms                                      |
| Validation    | Zod 3                                         | Used for both form schemas AND API response parsing                                              |
| Tables        | TanStack Table v8 via `TableV2`               | See `components/one-portal/wrappers/table-v2.md`; **never** use bare DLS `Table` or the legacy `TableV1`    |
| i18n          | next-intl 4 + `@neeve/one-i18n`               | All user-facing strings via `useTranslations()` — no hardcoded English strings                   |
| Drag & drop   | `@dnd-kit/*`                                  | Already in the bundle; use it instead of other DnD libraries                                     |
| Dates         | `date-fns` + `date-fns-tz`                    | Do not reach for `dayjs`, `moment`, or `Temporal`                                                |
| Testing       | Jest 29 + Testing Library                     | 335 test files under `__tests__/` — mirror `app/` and `shared/` folder structure                 |

---

## Project layout & file placement

```
one-portal/
├── app/                         ← Next.js routes + colocated route-specific UI
│   └── <route>/
│       ├── page.tsx             ← Thin composition shell — imports from _internal/
│       └── _internal/
│           ├── containers/      ← Data-connected containers (query hooks + store)
│           ├── components/      ← Presentational components used only by this route
│           ├── hooks/           ← Route-local hooks
│           ├── queries/         ← Route-local TanStack Query hooks (if not in shared/)
│           ├── store/           ← Route-local Zustand store (if not in shared/)
│           ├── schema/          ← Route-local Zod schemas
│           └── lib/ · utils/   ← Route-local helpers
├── shared/
│   ├── services/                ← axios API client classes (HttpService subclasses)
│   ├── queries/                 ← TanStack Query hooks shared across routes
│   ├── schema/                  ← Zod schemas for shared API responses
│   ├── store/                   ← Zustand stores shared across routes
│   ├── hooks/                   ← Reusable hooks (debounce, scopes, CSV export…)
│   ├── components/              ← Shared UI (TableV2 family, LeftNav, AccessGate…)
│   └── lib/                     ← Utilities (cn, constants, error handlers…)
└── lib/                         ← Top-level constants (ENV, pagination defaults, CSV limits)
```

### Where to place new code

| What you're adding                           | Where it goes                                                  |
| -------------------------------------------- | -------------------------------------------------------------- |
| UI used only by one route                    | `app/<route>/_internal/components/` or `_internal/containers/` |
| UI reused across ≥ 2 routes                  | `shared/components/`                                           |
| Query hook used only by one route            | `app/<route>/_internal/queries/`                               |
| Query hook reused across routes              | `shared/queries/<domain>/`                                     |
| Zod schema for API response                  | `shared/schema/`                                               |
| Zustand store for cross-route state          | `shared/store/`                                                |
| Route-only utility / helper                  | `app/<route>/_internal/lib/` or `utils/`                       |
| Shared utility                               | `shared/lib/`                                                  |
| Top-level env constant or pagination default | `lib/constants.ts`                                             |

**Never** put business logic directly in `page.tsx`. `page.tsx` must only compose
containers and handle layout; it should have no `useState`, `useEffect`, or query
hooks of its own.

---

## Naming conventions

| Item                   | Convention                                    | Example                                        |
| ---------------------- | --------------------------------------------- | ---------------------------------------------- |
| Component files        | PascalCase `.tsx`                             | `NodeDetailCard.tsx`                           |
| Hook files             | camelCase `.ts` starting with `use`           | `useNodeStatus.ts`                             |
| Service files          | PascalCase + `.service.ts` suffix             | `NodeService.ts`                               |
| Schema files           | camelCase + `.schema.ts` suffix               | `node.schema.ts`                               |
| Store files            | camelCase `.ts` (no suffix)                   | `nodeStatus.ts`                                |
| Constant / util files  | camelCase `.ts`                               | `handleAxiosError.ts`                          |
| Test files             | mirror source path + `.test.tsx` / `.test.ts` | `__tests__/shared/components/TableV2.test.tsx` |
| Route folders          | lowercase kebab-case                          | `setup-node/`, `security-and-authentication/`  |
| Internal route folders | underscore prefix                             | `_internal/`, `_components/`, `_hooks/`        |
| Props interface        | `ComponentNameProps`                          | `NodeDetailCardProps`                          |
| Zod inferred type      | `SchemaNameT`                                 | `NodeSchemaT`                                  |

---

## Component file conventions

- **Functional components only** — no class components.
- **Named exports** for all components. Default exports are only used when Next.js
  requires them (route `page.tsx`, `layout.tsx`, `loading.tsx`, `not-found.tsx`).
- **Props type with interface**, named `ComponentNameProps`, defined in the same file
  (or a colocated `types.ts` if shared within the `_internal/` folder).
- **`"use client"`** directive at the top of any file that uses hooks, browser APIs,
  or event handlers. The root layout is `force-dynamic`; most interactive code is
  client-side.
- **No `React.FC` / `React.FunctionComponent`** annotations — just plain function
  signatures with typed props.
- Keep single-responsibility: containers fetch and transform data; components render.
  A container may render one or more presentational components; it should not itself
  contain complex JSX trees.

```tsx
// ✅ correct
"use client";

interface NodeCardProps {
  nodeId: string;
  name: string;
}

export function NodeCard({ nodeId, name }: NodeCardProps) {
  return <div>...</div>;
}

// ❌ wrong — default export, untyped props
export default function NodeCard(props: any) { ... }
```

---

## Import conventions

**Path alias:** `@/*` resolves to the project root (`./`). Always use `@/` for
non-relative imports.

**Import order** (enforced by ESLint `import/order`):

1. Node built-ins
2. External packages (`react`, `next/*`, `@tanstack/*`, `zod`, etc.)
3. `@neeve/dls` design system
4. `@/shared/*`
5. `@/lib/*`, `@/i18n/*`
6. Route-local imports (`@/app/<route>/_internal/*`)
7. Relative imports (`./`, `../`)

```tsx
// ✅ correct ordering
import { useState } from "react";
import { useTranslations } from "next-intl";
import { Button } from "@neeve/dls";
import { TableV2 } from "@/shared/components/table/TableV2";
import { useNodes } from "@/shared/queries/nodes/useNodes";
import { NodeCard } from "./NodeCard";
```

**Named imports only** from `@neeve/dls` and `@/shared/*` — never import the whole
module.

---

## Styling conventions

- Compose class names with **`cn()`** (`shared/lib/utils.ts`) — it wraps `clsx` +
  `tailwind-merge`. Never concatenate Tailwind class strings manually.
- Use **DLS spacing tokens** (`dls-p-400`, `dls-gap-200`) rather than vanilla
  Tailwind spacing (`p-4`, `gap-2`) when working with DLS-adjacent layouts. See
  `references/one-portal-design-tokens.md` for the full token scale.
- **Dynamic branding** is applied via CSS custom properties (`--custom-primary`,
  `--custom-secondary`, `--custom-tertiary`, `--custom-contrast`) set on
  `document.body` by `AppWrapper`. Reference these variables in custom styles when
  org-branded colours are needed.
- **No inline `style` objects** unless a dynamic value cannot be expressed in
  Tailwind (e.g. a runtime pixel value from a measurement).
- Responsive breakpoints: xs / sm / md / lg / xl — see `references/one-portal-design-tokens.md`.

---

## Data fetching conventions

Follow the **three-layer flow** strictly — never skip a layer:

```
Component / Container
  └─► Query hook  (shared/queries/<domain>/use*.ts)
        └─► Service class  (shared/services/*.service.ts)
              └─► axios (axiosInstance or secureEdgeAxiosInstance)
                    └─► Zod safeParse on response
```

### Query hooks (`shared/queries/`)

- One file per logical operation: `useNodes.ts`, `useCreateNode.ts`, etc.
- `useQuery` hooks: construct the service in `queryFn`, pass params from the caller.
- `useMutation` hooks: invalidate by query-key prefix in `onSettled`.
- Query keys are plain arrays: `["nodes", params, siteIds]`.
- `enabled` guard when the hook depends on data that may not yet be available
  (`enabled: !!nodeId && !isAccessRestricted`).

### Service classes (`shared/services/`)

- Each service extends `HttpService`.
- Every public method calls `requestWithAxios` or `requestWithSecureEdgeProxy`, then
  `safeParse`s the response against its Zod schema before returning.
- Endpoint URLs live in an `apiEndpointsUsed` map inside the service — never scatter
  URL strings through query hooks or components.

### Pagination

- Use TanStack `PaginationState` (`{ pageIndex, pageSize }`).
- Services build query strings with `getURLParams` (`shared/lib/utils.ts`) and append
  `page` / `size`.
- Default pagination constants live in `lib/constants.ts` (`DEFAULT_PAGINATION`,
  `PAGE_SIZE_OPTIONS`).

### QueryClient defaults

`staleTime: 60s`, `refetchOnWindowFocus: false`, `refetchOnReconnect: true`. Do not
override these locally unless there is a specific reason.

---

## State management (Zustand)

- 13 single-purpose stores under `shared/store/`. Use the existing stores before
  creating a new one.
- Common stores: `useCurrentUserStore`, `useCurrentOrgStore`, `useSitesStore`,
  `useBrandingStore`, `useUIShellStore`, `environmentVariablesStore`,
  `useTableStore`.
- `AppWrapper` is the central hydration point; stores are already populated by the
  time route components mount — read synchronously, do not re-fetch.
- **Never** use React `Context` for state that needs to persist across routes or be
  accessed from sibling subtrees. Use Zustand.
- Route-local ephemeral state (`useState`) is fine for UI-only state (open/close,
  hover, input value before submit).

---

## Forms (react-hook-form + Zod)

- Always `useForm({ resolver: zodResolver(schema) })`.
- Wrap DLS inputs with `Controller` — they are controlled components.
- Zod schemas are factory functions when they need the `t` translator for localised
  error messages: `const schema = (t: Translations) => z.object({ ... })`.
- Expose `submitForm()` via `forwardRef` + `useImperativeHandle` when a parent
  dialog or stepper needs to trigger submission imperatively.
- Map HTTP 422 validation errors back onto fields with `handleAxiosErrorWithForm`
  from `shared/lib/handleAxiosError.ts`.

---

## Authorization (RBAC)

- Wrap any UI that requires a permission with `<AccessGate requiredScopes={[...]}>`
  or `<PermissionGate>` from `shared/components/`.
- `useAccessRestricted()` must gate any query with `enabled: !isAccessRestricted`.
- Never hard-code role strings in components — role/scope constants come from
  `shared/lib/utils.ts` or the existing scope lists.
- On access denial, `AccessGate` redirects to `/unauthorized` automatically — do
  not add manual redirect logic.

---

## i18n

- **No hardcoded English strings** in JSX or user-facing messages.
- `const t = useTranslations("namespace")` at the top of every client component that
  renders text.
- Message keys come from `@neeve/one-i18n` catalogs. When adding a new string,
  add the key to the catalog source; do not invent keys that don't exist.
- Locale is currently fixed to `"en"` — do not add locale-switching logic.

---

## TypeScript conventions

- `strict: false`, `strictNullChecks: false` — the codebase does not use strict null
  checks. **Do not** add `!` non-null assertions or `?? undefined` fallbacks
  everywhere; they will be inconsistent with surrounding code.
- Path alias `@/*` → `./` (project root). Always use `@/` not relative `../../`.
- Inferred types from Zod: use `z.infer<typeof MySchema>` and export as `MySchemaT`.
- Avoid `any` where a reasonable type is available, but do not fight the compiler for
  complex generics — a well-placed `// eslint-disable-next-line` is preferable to
  unreadable workarounds.

---

## Testing expectations

- Tests live under `__tests__/` mirroring the source path:
  `__tests__/shared/components/NodeCard.test.tsx`.
- Use Jest 29 + `@testing-library/react`.
- The `@/*` alias and CSS modules are stubbed in `jest.config.ts` — no additional
  setup needed.
- ESM-only packages (`uuid`, `next-intl`, `@formatjs/*`) are transpiled via
  `transformIgnorePatterns` — do not add them to `moduleNameMapper`.
- Design-team prototypes handed off via this skill do **not** require tests before
  handoff — tests are engineering's responsibility post-handoff. However, any code
  placed in `shared/` must have accompanying tests.

---

## Linting & formatting

- **ESLint 9** flat config (`eslint.config.mjs`) with an Airbnb-influenced rule set.
- **Prettier 3** + `prettier-plugin-tailwindcss` (auto-sorts Tailwind classes).
- Husky + lint-staged run `eslint --fix` and `prettier --write` on staged files
  pre-commit.
- `import/order` rule is active — maintain the import order described above.
- The production build intentionally ignores ESLint and TypeScript errors
  (`eslint.ignoreDuringBuilds: true`, `typescript.ignoreBuildErrors: true`). Lint and
  `type-check` run as separate CI steps. **Do not** assume a clean build means clean
  lint.

---

## Build & CI notes

- `npm run dev` runs `scripts/dev-check.ts` first (WAN-IP prompt) then `next dev`
  with `NODE_TLS_REJECT_UNAUTHORIZED=0`.
- `npm run build` / `npm run build:ci` produce a standalone Next.js output.
- Dockerized for deployment (`Dockerfile`, `entrypoint.sh`). CI via Bitbucket
  Pipelines; SonarQube configured.
- `npm run type-check` and `npm run lint` are separate scripts — run both before
  marking code complete.
