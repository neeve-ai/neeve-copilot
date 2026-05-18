# Security Checklist for Spec Writing

Integrated from CoSAI Project CodeGuard + OWASP ASVS.
Load this when writing the Security section of any spec.

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
