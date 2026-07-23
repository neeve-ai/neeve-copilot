# Security Checklist for Spec Writing

Integrated from CoSAI Project CodeGuard + OWASP ASVS.
Load this when writing the Security section of any spec.

**See also:** `code-review/references/security.md` — the deeper reference
this checklist is a spec-time subset of. Its Pentest Mindset (adversarial
actor-by-actor) and Escalation ("needs a decision, not just a fix") sections
are code-review-timed by design, not duplicated here — but its Enterprise
SaaS Multi-Tenancy and SSRF content is spec-shaping, not just review-shaping,
so the checklist below pulls those items forward rather than leaving them to
surface for the first time at Stage 6.

---

## Always-On Checks (every spec, every section)

### Credentials & Secrets
- [ ] No hardcoded secrets in any code path specified
- [ ] Secrets injected via env vars from Kubernetes SecretKeyRef or KMS
- [ ] No secrets in logs (not even at DEBUG level)
- [ ] No secrets in NATS/event payloads unless encrypted end-to-end

### Input Validation
- [ ] Every external input has a validation boundary named (who validates it, at what layer)
- [ ] SQL: parameterized queries only — no string formatting into queries
- [ ] File uploads: content-type validation, size cap, stored outside web root
- [ ] No `eval()`, `exec()`, `pickle.loads()` on untrusted input
- [ ] `yaml.safe_load()` not `yaml.load()`

### Authentication
- [ ] JWT algorithm explicitly pinned — "alg: none" rejected
- [ ] Token expiry validated (`exp`, `iat`, `nbf`)
- [ ] Constant-time comparison for secrets (`hmac.compare_digest`)
- [ ] No auth derivation from headers or JWT role claims alone

### Authorization (fail-closed)
- [ ] Every resource access scoped to current user/org (IDOR prevention)
- [ ] Deny is the default — access is explicitly granted, not denied
- [ ] Authorization source (FGA, RBAC table) is the authority — not a cache
- [ ] Cache unavailability → fall through to auth source (not open)
- [ ] Auth source unavailability → 503 fail-closed (not open)

### Logging & Audit
- [ ] PII (email, name, IP) anonymized or hashed before logging
- [ ] Correlation/request IDs on every log line
- [ ] Deny decisions audited synchronously (before response returned)
- [ ] Allow decisions audited at configurable sample rate (async)
- [ ] No stack traces, internal IDs, or FGA payloads in HTTP response bodies

### Cryptography
- [ ] No MD5, SHA-1, DES, 3DES, RC4, AES-ECB, or AES-CBC
- [ ] Password hashing: Argon2id (preferred), bcrypt ≥ cost 10, PBKDF2-HMAC-SHA-256 ≥600k
- [ ] Symmetric encryption: AES-256-GCM or ChaCha20-Poly1305
- [ ] TLS 1.3 enforced for all external connections

---

## Conditional Checks (apply when relevant)

### When spec touches HTTP endpoints
- [ ] CSRF protection on state-changing endpoints
- [ ] Rate limiting on auth, registration, password reset endpoints
- [ ] CORS configured — not `allow_origins=["*"]` in production
- [ ] Security headers: CSP, HSTS, X-Frame-Options, X-Content-Type-Options
- [ ] 403 body does not leak internal resource existence (use 404 when appropriate)

### When spec touches databases
- [ ] Connection strings from secrets, not env literals
- [ ] DB user has least-privilege permissions (not admin/root)
- [ ] Connection pooling — no per-request connections
- [ ] No direct ORM model binding to request body (mass assignment prevention)

### When spec touches message queues (NATS, Kafka, SQS)
- [ ] Consumer is idempotent (at-least-once delivery is the default)
- [ ] Message schema validated on consume (not trusted blindly)
- [ ] No PII in message subjects/keys
- [ ] Dead-letter queue or retry with backoff specified

### When spec touches Kubernetes
- [ ] `runAsNonRoot: true`
- [ ] `readOnlyRootFilesystem: true`
- [ ] `allowPrivilegeEscalation: false`
- [ ] `capabilities: drop: [ALL]`
- [ ] Secrets via SecretKeyRef, not ConfigMap
- [ ] NetworkPolicy defined (default-deny with explicit allows)
- [ ] RBAC: service account with minimal verbs and resourceNames-scoped rules

### When spec touches caching (Redis)
- [ ] Cache keys use stable internal IDs (UUID), not PII (email, username)
- [ ] TTL set on every key — no infinite-TTL cache entries
- [ ] Cache miss falls through to source of truth — never fails open
- [ ] Cache poisoning: validate data on read if written by untrusted path

### When spec touches supply chain
- [ ] Dependency versions pinned (== not >=)
- [ ] `pip install --require-hashes` or `npm ci` in CI
- [ ] SBOM generation noted if adding new dependencies
- [ ] No `latest` image tags

### When spec touches multi-tenant data (most features — Neeve is multi-tenant SaaS)
- [ ] **Tenant isolation is named as its own check, distinct from IDOR.** IDOR
      asks "does this user own this resource"; tenant isolation asks "is this
      resource's tenant/org ID the same as the session's" — a query can pass
      the first and still leak across tenants. State which one each access
      check enforces, not just "authorization is scoped."
- [ ] Tenant ID filter is a `WHERE` clause derived from the authenticated
      session — never from a client-supplied field, never an
      application-layer post-filter on an unscoped query
- [ ] Rate limits on shared infrastructure are keyed by tenant/org ID, not
      only IP or global to the service (a noisy-neighbor tenant shouldn't
      degrade every other tenant)
- [ ] Sensitive actions (role change, data export, credential rotation) have
      a named audit-trail requirement — an append-only record, not a debug
      log line
- [ ] Service credentials for this feature are scoped to the integration/
      tenant that needs them, not blanket access across all tenants

### When spec touches outbound requests to a user/tenant-supplied URL (webhooks, integrations, fetch-by-URL, "test connection")
- [ ] **SSRF is named explicitly**, not folded into generic "input
      validation" — any server-side fetch of a URL that's directly or
      indirectly attacker/tenant-supplied is an SSRF vector
- [ ] Target is validated against a deny-list (RFC1918 ranges, link-local
      `169.254.0.0/16` — cloud metadata endpoints — and localhost) **after**
      DNS resolution, not just the hostname string (defends against
      DNS-rebinding)
- [ ] Outbound webhooks to customer endpoints are HMAC-signed so the
      customer can verify authenticity
- [ ] Inbound webhooks from third parties verify the provider's signature
      before the payload is trusted

---

## Security Section Template

Use this structure for the Security section of every spec:

```markdown
## Security

### Fail-closed model
[Describe what happens when each dependency (auth service, cache, DB) is unavailable.
Every failure mode must fail closed or degrade gracefully with explicit rationale.]

### Authentication & authorisation
[What authenticates callers? What authorises resource access? Where is the authority?]

### PII handling
[What PII does this feature touch? How is it stored, logged, and transmitted?]

### Secret management
[What secrets does this feature need? How are they injected? Where do they live?]

### Input validation surface
[What external inputs does this feature accept? Where is each validated?]

### Audit trail
[What events are audited? Synchronous or async? What fields are written?]
```
