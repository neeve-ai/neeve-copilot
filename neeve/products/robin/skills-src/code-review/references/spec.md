# Spec Compliance & Scope Creep Reference

## Locating the Spec

Check for spec artifacts in this order:

1. `.md` file in  `specs/`
2. Look for "Requirements", "API Contract", "Acceptance Criteria" sections
3. Docstrings on module or class level describing expected behavior
4. OpenAPI / AsyncAPI schema files (`openapi.yaml`, `openapi.json`)
5. Test file names and docstrings — tests often encode implied spec
6. Issue tracker references in comments (`# See JIRA-123` or `# See GH-456`)

**If no spec found:** Emit a MEDIUM finding:
> "No specification file found. Add a SPEC.md or equivalent to document expected behavior,
> API contracts, and acceptance criteria. This makes scope creep detectable."

---

## Spec Gap Analysis

For each requirement in the spec:

| Check | Finding tier |
|-------|-------------|
| Requirement implemented | ✅ Pass |
| Requirement missing entirely | 🟠 HIGH spec gap |
| Requirement partially implemented | 🟡 MEDIUM partial implementation |
| Requirement implemented differently than spec | 🟡 MEDIUM divergence — document the reason |
| Implementation exists but NOT in spec | 🟠 HIGH scope creep (unless explicitly deferred) |

### Example output

```
[S1] 🟠 HIGH — Spec Gap: Authentication endpoint
  Spec requires: POST /auth/refresh with refresh token rotation
  Found: No refresh endpoint; only /auth/login exists
  Impact: Sessions expire and cannot be renewed without re-login

[S2] 🟠 HIGH — Scope Creep: Admin dashboard routes
  Found: /admin/users, /admin/metrics, /admin/config endpoints
  Spec: No admin routes defined in spec
  Risk: Unreviewed surface area deployed to production
  Action: Either add to spec or remove before merge
```

---

## OpenAPI Contract Checking

If an OpenAPI spec exists, verify:

- Every route in code is documented in the spec
- Every route in spec is implemented in code
- Request body schemas match (field names, required fields, types)
- Response schemas match (status codes, body shape)
- Error responses documented (400, 401, 403, 404, 422, 500)
- Path parameters in spec match route parameters in code

```python
# Flag: code returns a field not in spec response schema
# → breaking change for API consumers even if "just adding a field"

# Flag: code accepts fields spec says are forbidden
# → security risk (mass assignment)
```

---

## Scope Creep Patterns

### Feature flags masking scope creep
```python
# This IS scope creep even if behind a flag
if settings.ENABLE_EXPERIMENTAL_BILLING:
    # 800 lines of billing logic not in spec
```

### "While I was in there" additions
Look for functions/classes that don't map to any spec requirement but were added opportunistically.
Flag them for explicit spec inclusion or removal.

### Dependency bloat as scope indicator
New dependencies added that no spec requirement necessitates → ask why.

---

## No-Spec Inference (when spec is absent)

When no spec exists, infer intent from:
1. Function/class names and docstrings
2. Test file assertions (what behavior tests assert = implied spec)
3. README usage examples
4. Existing API routes (the URL shape tells you the intended contract)

Then flag logical deviations from the inferred spec as MEDIUM findings.
