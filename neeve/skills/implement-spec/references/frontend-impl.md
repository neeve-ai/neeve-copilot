# Frontend Implementation Reference

## Pre-Implementation Checklist

Before writing any component:

1. **What layer does this belong to?** Presentational / container / hook / service / store
2. **What is the single responsibility?** State one sentence. If you need "and", split it.
3. **Where does state live?** Local / server (React Query) / global (Zustand) — choose the
   smallest scope that satisfies the requirement.
4. **What are the loading, empty, and error states?** All three must be designed and tested.
5. **What user journey does this serve?** Trace to a FR number.
6. **What are the security implications?** User input? PII displayed? Auth-gated?

---

## Component Layering (enforced in file structure)

```
presentation/     Pure render — receives data as props, emits events via callbacks
                  No fetching, no state mutations, no side effects in render
                  
container/        Orchestrates data fetching and state for a feature
                  Uses hooks, passes data down to presentational components
                  
hooks/            Encapsulates stateful logic — fetch, mutation, derived state
                  Testable in isolation without rendering
                  
services/         Pure functions — API calls, data transforms, formatters
                  No React imports, no hooks, fully unit-testable
                  
store/            Global shared client state only
                  Never holds server state (that's React Query's job)
```

---

## Component Contract Pattern

```typescript
// ✅ CORRECT — explicit, typed, documented interface
interface PolicyAllowlistProps {
  readonly domains: readonly string[]
  readonly isLoading: boolean
  readonly error: Error | null
  readonly onAdd: (domain: string) => void
  readonly onRemove: (domain: string) => void
  readonly canEdit: boolean  // derived from RBAC, passed from container
}

export function PolicyAllowlist({
  domains,
  isLoading,
  error,
  onAdd,
  onRemove,
  canEdit,
}: PolicyAllowlistProps): JSX.Element {
  if (isLoading) return <PolicyAllowlistSkeleton />
  if (error) return <PolicyAllowlistError error={error} />
  if (domains.length === 0) return <PolicyAllowlistEmpty canEdit={canEdit} />

  return (
    <ul role="list" aria-label="Domain allowlist">
      {domains.map((domain) => (
        <DomainItem
          key={domain}
          domain={domain}
          onRemove={canEdit ? () => onRemove(domain) : undefined}
        />
      ))}
    </ul>
  )
}
```

---

## Data Fetching: React Query Pattern

```typescript
// hooks/usePolicyAllowlist.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { fetchAllowlist, addDomain, removeDomain } from '../services/policyApi'
import type { Domain } from '../types'

const ALLOWLIST_KEY = (orgId: string) => ['policy', 'allowlist', orgId] as const

export function usePolicyAllowlist(orgId: string) {
  const queryClient = useQueryClient()

  const query = useQuery({
    queryKey: ALLOWLIST_KEY(orgId),
    queryFn: () => fetchAllowlist(orgId),
    staleTime: 30_000,   // 30s — domain list changes rarely
    retry: 3,
  })

  const addMutation = useMutation({
    mutationFn: (domain: string) => addDomain(orgId, domain),
    onSuccess: () => {
      // Invalidate and refetch — optimistic update only if latency matters
      queryClient.invalidateQueries({ queryKey: ALLOWLIST_KEY(orgId) })
    },
    onError: (error: Error) => {
      // Let the UI know — don't swallow
      console.error('Failed to add domain:', error.message)
    },
  })

  return {
    domains: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    addDomain: addMutation.mutate,
    isAdding: addMutation.isPending,
    removeDomain: ...,
  }
}
```

---

## API Service: Typed, Validated, Auth-Aware

```typescript
// services/policyApi.ts
import { z } from 'zod'

// Response schema — validate shape on every call
const AllowlistSchema = z.object({
  domains: z.array(z.string().min(1).max(253)),
})

export type Allowlist = z.infer<typeof AllowlistSchema>

export async function fetchAllowlist(orgId: string): Promise<Allowlist> {
  const resp = await fetch(`/api/orgs/${encodeURIComponent(orgId)}/policy/allowlist`, {
    credentials: 'include',   // HttpOnly auth cookie
    headers: { 'Accept': 'application/json' },
  })

  if (resp.status === 401) throw new UnauthorizedError('Session expired')
  if (resp.status === 403) {
    const body = await resp.json()
    throw new ForbiddenError(body.error, body.role, body.resource, body.action)
  }
  if (!resp.ok) throw new ApiError(resp.status, `Failed to fetch allowlist: ${resp.statusText}`)

  const data = await resp.json()
  return AllowlistSchema.parse(data)  // throws ZodError if shape is wrong
}
```

---

## Error Typed Hierarchy

```typescript
// types/errors.ts
export class ApiError extends Error {
  constructor(public readonly status: number, message: string) {
    super(message)
    this.name = 'ApiError'
  }
}

export class UnauthorizedError extends ApiError {
  constructor(message = 'Unauthorized') { super(401, message) }
}

export class ForbiddenError extends ApiError {
  constructor(
    public readonly rbacError: string,
    public readonly role: string,
    public readonly resource: string,
    public readonly action: string,
  ) {
    super(403, `rbac_denied: ${role} cannot ${action} ${resource}`)
  }
}
```

---

## Security: Input Handling

```typescript
// NEVER — raw user input in DOM
const DomainInput = ({ onAdd }) => {
  const [value, setValue] = useState('')
  return (
    <div>
      <input value={value} onChange={e => setValue(e.target.value)} />
      {/* WRONG — XSS if domain contains HTML */}
      <div dangerouslySetInnerHTML={{ __html: `Adding: ${value}` }} />
    </div>
  )
}

// CORRECT — text content only, validated before submit
const DomainInput = ({ onAdd }) => {
  const [value, setValue] = useState('')
  const [error, setError] = useState<string | null>(null)

  const handleSubmit = () => {
    // Client-side validation: UX only, not security
    if (!DOMAIN_REGEX.test(value)) {
      setError('Enter a valid domain (e.g. example.com)')
      return
    }
    onAdd(value.trim().toLowerCase())  // normalized
    setValue('')
    setError(null)
  }

  return (
    <form onSubmit={e => { e.preventDefault(); handleSubmit() }}>
      <input
        type="text"
        value={value}
        onChange={e => setValue(e.target.value)}
        aria-label="Domain to add"
        aria-describedby={error ? 'domain-error' : undefined}
        aria-invalid={error !== null}
      />
      {error && <p id="domain-error" role="alert">{error}</p>}
      <button type="submit">Add domain</button>
    </form>
  )
}
```

---

## Test Structure: RTL + msw

```typescript
// __tests__/PolicyAllowlist.test.tsx
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { http, HttpResponse } from 'msw'
import { setupServer } from 'msw/node'
import { PolicyAllowlistContainer } from '../PolicyAllowlistContainer'
import { createWrapper } from '@/test/helpers'

const server = setupServer(
  http.get('/api/orgs/:orgId/policy/allowlist', () =>
    HttpResponse.json({ domains: ['example.com', 'test.org'] })
  )
)

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

describe('PolicyAllowlist — admin user', () => {
  it('displays existing domains from API', async () => {
    /**
     * FR-16: GET /policy/allowlist guarded by can_view_domain_filter.
     * UC-3: viewer views the domain allowlist.
     * Journey: If domains don't render, admins cannot see what's on the allowlist.
     */
    render(<PolicyAllowlistContainer orgId="org_TEST" />, { wrapper: createWrapper() })

    await waitFor(() => {
      expect(screen.getByText('example.com')).toBeInTheDocument()
      expect(screen.getByText('test.org')).toBeInTheDocument()
    })
  })

  it('shows error state when API returns 403', async () => {
    /**
     * FR-13: rbac_denied 403 response body shape.
     * Journey: Unauthorized user lands on page — must see access denied, not a broken page.
     */
    server.use(
      http.get('/api/orgs/:orgId/policy/allowlist', () =>
        HttpResponse.json(
          { error: 'rbac_denied', role: 'viewer', resource: 'domain_filter', action: 'read' },
          { status: 403 }
        )
      )
    )

    render(<PolicyAllowlistContainer orgId="org_TEST" />, { wrapper: createWrapper() })

    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent(/access denied/i)
    })
    // Domains must not be visible
    expect(screen.queryByRole('list')).not.toBeInTheDocument()
  })
})
```

---

## Accessibility Checklist (per component)

- [ ] All interactive elements reachable by Tab
- [ ] Buttons have accessible names (text content or `aria-label`)
- [ ] Form inputs have associated labels (`htmlFor` / `aria-label`)
- [ ] Loading states announced: `aria-live="polite"` or `aria-busy="true"`
- [ ] Error messages associated with their inputs: `aria-describedby` / `aria-invalid`
- [ ] Lists use `role="list"` with `aria-label`
- [ ] Focus management on modal open/close
- [ ] Color is not the only indicator of state (icons + text + color)
