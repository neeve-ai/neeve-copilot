# Frontend Standards Reference (FAANG-Level)

## Component Architecture

### Principles
- **Single responsibility**: one component does one thing. A `UserCard` renders a user.
  A `UserCardContainer` fetches data. Never both in the same component.
- **Pure by default**: components are pure functions of their props. Side effects (fetch,
  subscriptions, timers) live in hooks or container components, never inline in render.
- **Composable**: prefer composition over inheritance. Small, focused components that
  combine into larger ones.
- **Independently testable**: every component can be rendered in isolation with mock props.

### File structure

```
src/
├── components/           # Pure presentational components
│   └── [Component]/
│       ├── [Component].tsx
│       ├── [Component].test.tsx
│       ├── [Component].stories.tsx  # (if Storybook)
│       └── index.ts                 # named export only
├── hooks/                # Custom hooks (stateful logic)
│   ├── use[Feature].ts
│   └── use[Feature].test.ts
├── services/             # API clients, external integrations
├── store/                # Global state (Zustand / Redux / Jotai)
├── types/                # Shared TypeScript types
└── utils/                # Pure utility functions
```

---

## TypeScript Standards

```typescript
// Always: explicit return types on exported functions
export function formatCurrency(amount: number, currency: string): string { ... }

// Always: interfaces for object shapes, types for unions
interface UserProfile { id: string; email: string; role: Role }
type Role = "viewer" | "operator" | "admin" | "super_admin"

// Never: `any` — use `unknown` and narrow
function parseApiResponse(data: unknown): UserProfile {
  if (!isUserProfile(data)) throw new ParseError("Invalid shape")
  return data
}

// Always: readonly on props and state that shouldn't mutate
interface ComponentProps { readonly items: readonly Item[] }

// Never: non-null assertion (!) without a comment explaining why it's safe
const el = document.getElementById("root")! // safe: index.html guarantees this element exists
```

---

## State Management

### Local state: `useState` / `useReducer`
Use for UI state that doesn't need to be shared (open/closed, form input, hover).

### Server state: React Query / SWR
Use for data fetched from APIs. Never manually manage loading/error state for server data.

```typescript
// CORRECT — React Query handles loading, error, cache, refetch
const { data: user, isLoading, error } = useQuery({
  queryKey: ["user", userId],
  queryFn: () => fetchUser(userId),
  staleTime: 5 * 60 * 1000,  // 5 min cache
})

// WRONG — manual fetch with useEffect
useEffect(() => {
  fetch(`/api/users/${userId}`).then(r => r.json()).then(setUser)
}, [userId])
```

### Global state: Zustand / Jotai
Use for client-side state shared across components (auth session, theme, feature flags).
Never put server state in global store.

```typescript
// Zustand — flat slices, no GOD store
const useAuthStore = create<AuthState>((set) => ({
  user: null,
  setUser: (user: User | null) => set({ user }),
  clearUser: () => set({ user: null }),
}))
```

---

## Security

### XSS Prevention
```typescript
// NEVER — dangerouslySetInnerHTML with unvalidated content
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// CORRECT — always sanitize, or avoid raw HTML entirely
import DOMPurify from 'dompurify'
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />
```

### Storage
```typescript
// NEVER — storing tokens in localStorage (XSS accessible)
localStorage.setItem("access_token", token)

// CORRECT — HttpOnly cookies (set by server, not JS accessible)
// OR: in-memory state only (cleared on tab close)
const useAuthStore = create<AuthState>(() => ({ token: null }))
```

### Content Security Policy
Spec must include CSP headers:
```
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self' https://api.yourdomain.com
```

### Input sanitization
All user input displayed in the UI passes through sanitization before insertion.
Form inputs validated on client AND server (client validation is UX, not security).

---

## Performance Standards

### Bundle size budgets

| Bundle | Max size (gzipped) |
|--------|--------------------|
| Initial JS | 200 KB |
| Per-route chunk | 100 KB |
| CSS | 50 KB |

### Core Web Vitals targets (Lighthouse in CI)
- LCP: ≤ 2.5s
- FID / INP: ≤ 100ms
- CLS: ≤ 0.1
- Lighthouse Performance score: ≥ 90

### Performance patterns
- Route-based code splitting: `React.lazy(() => import('./Page'))`
- Image lazy loading: `<img loading="lazy" />`
- No layout thrash: read DOM measurements in `useLayoutEffect`, never in render
- Memoization: `useMemo` / `useCallback` for expensive computations or stable references
  passed to memoized children — not as a default on every component

---

## Accessibility

Every interactive element must be:
- Reachable by keyboard
- Labelled (visible label or `aria-label`)
- Announcing state changes to screen readers (`aria-live` for async updates)
- Tested with `@testing-library/jest-dom` a11y assertions

---

## Error Boundaries

Every page-level and feature-level component tree must have an error boundary:

```typescript
// features/[Feature]/index.tsx
export function FeaturePage() {
  return (
    <ErrorBoundary fallback={<FeatureErrorFallback />}>
      <Suspense fallback={<FeatureLoadingSkeleton />}>
        <FeatureContent />
      </Suspense>
    </ErrorBoundary>
  )
}
```

---

## API Client Standards

```typescript
// services/api.ts
// CORRECT — typed, error-normalizing API client
export async function fetchResource<T>(
  path: string,
  schema: ZodSchema<T>,
  options?: RequestInit,
): Promise<T> {
  const resp = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: { "Content-Type": "application/json", ...options?.headers },
    credentials: "include",  // send HttpOnly cookies
  })

  if (resp.status === 401) throw new UnauthorizedError()
  if (resp.status === 403) throw new ForbiddenError(await resp.json())
  if (!resp.ok) throw new ApiError(resp.status, await resp.text())

  const data = await resp.json()
  return schema.parse(data)  // validate response shape with Zod
}
```

---

## Spec Output for Frontend Tasks

When a spec involves frontend work, each task must specify:

1. **Component tree** — which components are new, which are modified
2. **State location** — local / server (React Query) / global (Zustand)
3. **API contract** — exact endpoint, request/response types (Zod schema)
4. **Accessibility** — ARIA roles, keyboard interactions
5. **Error states** — loading, empty, error — each must be designed and tested
6. **Security** — inputs sanitized, no PII in localStorage, CSP compliance
7. **Performance** — lazy loaded? memoized? bundle impact?
