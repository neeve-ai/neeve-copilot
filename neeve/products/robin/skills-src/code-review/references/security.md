# Security Reference (CoSAI Project CodeGuard — v1.3.1)

Source: https://github.com/cosai-oasis/project-codeguard (CC BY 4.0)
Integrated rules: crypto-algorithms, hardcoded-credentials, input-validation-injection,
authentication-mfa, authorization-access-control, supply-chain-security,
cloud-orchestration-kubernetes, data-storage, logging, api-web-services

---

## ALWAYS-ON RULES (apply to every file, every language)

### [CG-CRED] Hardcoded Credentials — CRITICAL

NEVER allow credentials in source. Flag anything matching:

| Pattern | Example |
|---------|---------|
| AWS keys | `AKIA...`, `ASIA...` |
| Stripe keys | `sk_live_`, `pk_live_` |
| Google API | `AIza` + 35 chars |
| GitHub tokens | `ghp_`, `gho_`, `ghu_`, `ghs_` |
| JWTs | three `.`-separated base64 sections starting `eyJ` |
| Private keys | `-----BEGIN ... PRIVATE KEY-----` |
| Credential URLs | `mongodb://user:pass@host`, `postgres://user:pass@` |
| Variable names | `password=`, `secret=`, `api_key=`, `token=` assigned a literal string |

```python
# CRITICAL
DB_PASSWORD = "hunter2"              # hardcoded
API_KEY = os.getenv("KEY", "abc123") # default is a live secret

# CORRECT
DB_PASSWORD = os.environ["DB_PASSWORD"]   # raises if missing — intentional
```

---

### [CG-CRYPTO] Cryptographic Algorithm Enforcement — CRITICAL

#### Banned algorithms — NEVER use, flag immediately:
- Hash: `MD2`, `MD4`, `MD5`, `SHA-0`
- Symmetric: `RC2`, `RC4`, `Blowfish`, `DES`, `3DES`
- Key Exchange: Static RSA, Anonymous Diffie-Hellman
- Classical: Vigenère

#### Deprecated (flag as HIGH — migrate):
- Hash: `SHA-1`
- Symmetric: `AES-CBC`, `AES-ECB`
- Signature: RSA with `PKCS#1 v1.5` padding
- Key Exchange: DHE with weak/common primes

#### Required — modern + post-quantum ready:
- **Symmetric**: AES-256-GCM or ChaCha20-Poly1305
- **Key Exchange**: ECDHE (X25519 or secp256r1); hybrid PQC (`X25519MLKEM768`) when supported
- **Signatures**: ECDSA P-256
- **TLS**: 1.3 only (never 1.0, 1.1, 1.2 if avoidable)
- **Password hashing**: Argon2id (preferred), scrypt, bcrypt ≥ cost 10; **NEVER MD5/SHA1 for passwords**

```python
# CRITICAL
import hashlib
hashed = hashlib.md5(password.encode()).hexdigest()  # MD5 for passwords

# CRITICAL
from Crypto.Cipher import DES   # banned algorithm

# CORRECT — password hashing
import argon2
ph = argon2.PasswordHasher(time_cost=2, memory_cost=19456, parallelism=1)
hash = ph.hash(password)

# CORRECT — symmetric encryption
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
key = AESGCM.generate_key(bit_length=256)
aesgcm = AESGCM(key)
ct = aesgcm.encrypt(nonce, plaintext, aad)
```

---

## CONDITIONAL RULES (apply when relevant files/patterns detected)

### [CG-INJECT] Input Validation & Injection Defense — CRITICAL when present

#### SQL Injection
```python
# CRITICAL — string formatting into SQL
query = f"SELECT * FROM users WHERE id = {user_id}"         # SQLi
query = "SELECT * FROM users WHERE id = " + request.id     # SQLi

# CORRECT — parameterized always
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))

# With SQLAlchemy ORM — correct
user = session.query(User).filter(User.id == user_id).first()
```

#### OS Command Injection
```python
# CRITICAL
os.system(f"ls {user_input}")                    # shell injection
subprocess.run(user_input, shell=True)           # shell=True with user input

# CORRECT
subprocess.run(["ls", safe_path], shell=False)   # structured, no shell
```

#### XSS (template injection)
```python
# CRITICAL — raw/unescaped output
return f"<html><body>{user_content}</body></html>"   # XSS

# CORRECT — use templating engine with auto-escape
from markupsafe import escape
return f"<html><body>{escape(user_content)}</body></html>"
```

#### Prototype Pollution (JavaScript/TypeScript)
```typescript
// HIGH — object literal with user-controlled keys
const config = Object.assign({}, userInput)          // prototype pollution risk

// CORRECT
const config = Object.assign(Object.create(null), userInput)
// Block: __proto__, constructor, prototype as keys
```

#### Deserialization (CRITICAL)
```python
# CRITICAL — arbitrary code execution
import pickle
data = pickle.loads(user_bytes)   # RCE if bytes are attacker-controlled

# CRITICAL
import yaml
data = yaml.load(user_input)      # use yaml.safe_load

# CORRECT
data = yaml.safe_load(user_input)
```

---

### [CG-AUTHN] Authentication — HIGH when auth code present

Key enforcement points:

- **Password storage**: Argon2id required; bcrypt ≥ cost 10 acceptable; PBKDF2-HMAC-SHA-256 ≥600k rounds for FIPS
- **No enumeration**: auth endpoints MUST return identical response for valid/invalid username
- **Constant-time comparison**: use `hmac.compare_digest()`, never `==` for secrets
- **JWT hardening**:
  - Explicitly pin algorithm — never accept `"alg": "none"`
  - Validate `iss`, `aud`, `exp`, `iat`, `nbf` on every verification
  - Short lifetimes; implement revocation denylist
- **OAuth 2.0**: Authorization Code + PKCE; never Implicit flow; strict redirect URI matching
- **Rate limiting**: auth endpoints require throttle — no exceptions
- **MFA**: WebAuthn/FIDO2 for high-value accounts; TOTP acceptable; SMS/email OTP NOT acceptable for sensitive accounts

```python
# CRITICAL — timing oracle on token comparison
if token == stored_token:   # timing attack possible

# CORRECT
import hmac
if not hmac.compare_digest(token, stored_token):
    raise Unauthorized()

# CRITICAL — JWT alg confusion
jwt.decode(token, key)    # no algorithms= parameter — accepts alg:none

# CORRECT
jwt.decode(token, key, algorithms=["HS256"])   # explicitly pinned
```

---

### [CG-AUTHZ] Authorization & Access Control — HIGH when resource access present

```python
# CRITICAL — IDOR: trusting user-supplied ID without ownership check
def get_order(order_id: int) -> Order:
    return db.query(Order).filter(Order.id == order_id).first()  # no owner check

# CORRECT — always scope to current user
def get_order(order_id: int, current_user: User) -> Order:
    order = db.query(Order).filter(
        Order.id == order_id,
        Order.user_id == current_user.id   # ownership enforced
    ).first()
    if not order:
        raise HTTPException(404)   # not 403 — avoids confirming existence
    return order

# HIGH — mass assignment: binding request body directly to model
class UserUpdate(BaseModel):
    email: str
    role: str          # HIGH — user can self-assign role
    is_admin: bool     # CRITICAL

# CORRECT — DTO with explicit allow-list
class UserUpdate(BaseModel):
    email: str         # only user-editable fields
```

**Deny by default**: every endpoint MUST have an explicit authorization check. Absence of a check = CRITICAL finding.

---

### [CG-SUPPLY] Supply Chain Security — HIGH for dependency files

Flag in `requirements.txt`, `pyproject.toml`, `package.json`, `Dockerfile`:

```
# HIGH — unpinned dependency (version can change under you)
requests>=2.28.0          # unpinned — use ==
flask                     # no version at all

# CORRECT
requests==2.32.3

# CRITICAL — image tag is `latest`
FROM python:latest        # non-deterministic

# CORRECT — pinned with digest
FROM python:3.12-slim@sha256:abc123...
```

Additional checks:
- `npm install` in CI → flag; require `npm ci` with lockfile
- `pip install` without `--require-hashes` → flag as MEDIUM
- Dependencies with known CVEs → CRITICAL if severity HIGH/CRITICAL in NVD
- Missing `SBOM` generation in CI pipeline → MEDIUM
- Missing image signature verification (Cosign/Sigstore) → MEDIUM

---

### [CG-K8S-SEC] Kubernetes Security Controls — maps to Axis 1 extended

Additional security controls beyond lifecycle (see `kubernetes.md`):

```yaml
# CRITICAL — running as root
securityContext:
  runAsRoot: true       # CRITICAL

# CRITICAL — privileged container
securityContext:
  privileged: true      # grants full host access

# HIGH — writable root filesystem
securityContext:
  readOnlyRootFilesystem: false   # should be true

# HIGH — excessive capabilities
securityContext:
  capabilities:
    add: ["NET_ADMIN", "SYS_ADMIN"]   # drop ALL, add only what's needed

# CORRECT baseline security context
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]

# HIGH — missing NetworkPolicy (all ingress/egress open by default)
# CORRECT — explicit deny-all with specific allow
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
---
# Then add specific allow rules per service
```

**RBAC minimum viable:**
```yaml
# HIGH — service account with cluster-admin
roleRef:
  kind: ClusterRole
  name: cluster-admin    # never for application service accounts

# CORRECT — namespace-scoped, minimal verbs
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list"]
    resourceNames: ["app-config"]  # resource-name scoped
```

---

### [CG-LOG] Secure Logging — MEDIUM always, CRITICAL if PII logged

```python
# CRITICAL — logging a secret/token
log.info(f"Auth token: {token}")
log.debug(f"Password: {password}")

# HIGH — logging PII without consent/anonymization
log.info(f"User {email} logged in from {ip}")   # PII

# CORRECT — log correlation IDs, not PII
log.info("auth.success", user_id=user.id, session_id=session_id, ip_hash=hash_ip(ip))
```

Rules:
- No secrets or tokens in logs — ever
- PII (email, name, SSN, IP) requires anonymization or explicit legal basis
- Correlation/trace IDs required on all log lines for distributed tracing
- Log level configurable via `LOG_LEVEL` env var
- Structured JSON format required (not free-form strings)

---

## Security Review Enforcement Prompts

Before finalizing security findings, verify:

1. **Have I scanned for hardcoded secrets?** Check every string literal near auth/config code.
2. **Have I checked the crypto stack?** MD5/SHA1/DES anywhere = CRITICAL.
3. **Have I traced every user input to its consumption point?** Is it parameterized or validated before use?
4. **Have I checked every resource access for ownership enforcement?** No IDOR = correct.
5. **Have I checked JWT/token handling?** Algorithm pinned? Expiry validated?
6. **Have I checked the container/pod security context?** Non-root, read-only FS, dropped capabilities?
7. **Have I reviewed dependency versions?** Pinned? Known CVEs?
8. **Have I checked logs for PII/secret leakage?**

---

## Security Severity Mapping

| CodeGuard Rule | Severity in Review |
|---------------|-------------------|
| Hardcoded credential (live key) | 🔴 CRITICAL |
| Banned crypto algorithm | 🔴 CRITICAL |
| SQL/OS injection | 🔴 CRITICAL |
| IDOR (no ownership check) | 🔴 CRITICAL |
| JWT alg:none accepted | 🔴 CRITICAL |
| Pickle/YAML.load on untrusted | 🔴 CRITICAL |
| Running as root in k8s | 🔴 CRITICAL |
| Deprecated crypto (SHA-1, AES-CBC) | 🟠 HIGH |
| Missing auth on endpoint | 🟠 HIGH |
| Mass assignment / no DTO | 🟠 HIGH |
| Unpinned base image tag | 🟠 HIGH |
| Missing RBAC scoping | 🟠 HIGH |
| Missing rate limiting on auth | 🟠 HIGH |
| PII in logs | 🟠 HIGH |
| Missing NetworkPolicy | 🟠 HIGH |
| Weak JWT config (short secret, no exp) | 🟠 HIGH |
| Missing SBOM / image signing | 🟡 MEDIUM |
| Unpinned dependency versions | 🟡 MEDIUM |
| SMS/email OTP for sensitive accounts | 🟡 MEDIUM |
| Missing Content-Security-Policy | 🟡 MEDIUM |
| Missing HSTS header | 🟡 MEDIUM |
| Secrets logged at DEBUG level | 🟡 MEDIUM |

---

## OWASP Top 10 (2021) — Coverage Map

Every rule above maps to an OWASP category. Use this table to sanity-check
coverage before closing out a security review — if a category has no
corresponding finding *and* no explicit "checked, not applicable" note, treat
that as a gap, not a clean bill of health.

| OWASP Category | Covered by | Gaps to check manually |
|---|---|---|
| A01 Broken Access Control | `[CG-AUTHZ]` (IDOR, mass assignment, deny-by-default) | CORS misconfiguration (`Access-Control-Allow-Origin: *` with credentials); path traversal (`../` in file params) |
| A02 Cryptographic Failures | `[CG-CRYPTO]` | TLS termination point (is plaintext HTTP used internally, e.g. pod-to-pod, and is that acceptable given the zero-trust default?) |
| A03 Injection | `[CG-INJECT]` (SQL, OS command, XSS, deserialization, prototype pollution) | **SSRF** — see below, not otherwise covered; template injection (SSTI) in Jinja2/Handlebars if user input reaches a template string |
| A04 Insecure Design | Judgment call, not a pattern grep — see "Pentest Mindset" below | Threat-model the feature: what happens if this endpoint/queue message is called by an authenticated-but-malicious actor, not just an unauthenticated one? |
| A05 Security Misconfiguration | `[CG-K8S-SEC]` | Debug/admin endpoints reachable in production (`/docs`, `/__debug__`, Django admin, Swagger UI exposed publicly); default credentials left on any bundled service (Redis, MinIO, Vault dev mode) |
| A06 Vulnerable and Outdated Components | `[CG-SUPPLY]` | — |
| A07 Identification and Authentication Failures | `[CG-AUTHN]` | Session fixation (session ID not rotated on login); missing logout/session revocation on password change |
| A08 Software and Data Integrity Failures | `[CG-SUPPLY]` (SBOM, image signing), deserialization rules in `[CG-INJECT]` | CI/CD pipeline itself — does a PR from a fork run with secrets access? Unsigned/unverified webhook payloads processed as trusted input |
| A09 Security Logging and Monitoring Failures | `[CG-LOG]` | Is there alerting on repeated auth failures / privilege-escalation attempts, or only passive logging? |
| A10 Server-Side Request Forgery (SSRF) | Not covered above — see next section | Any code path where the server fetches a URL supplied (directly or indirectly) by a user, webhook config, or integration setting |

### SSRF (the OWASP gap this repo needs explicit coverage for)

Relevant anywhere a service fetches a user- or tenant-supplied URL: webhook
delivery, integration configs, "test connection" endpoints, image/file
fetch-by-URL, health-check probes against customer-supplied hosts.

```python
# CRITICAL — server-side fetch of an unvalidated, user-supplied URL
resp = requests.get(user_supplied_webhook_url)

# CORRECT — resolve, then validate against a deny-list before connecting
# (block RFC1918 ranges, link-local 169.254.0.0/16 — cloud metadata endpoints —
# and 0.0.0.0/localhost) and re-validate after DNS resolution, not just the
# hostname string, to defend against DNS-rebinding
```

🔴 CRITICAL if a server-side request target is attacker/tenant-influenced with
no network-level or allow-list validation — this is a live concern for any
integration/webhook feature, not a theoretical one.

---

## Pentest Mindset — Adversarial Checks (beyond static pattern-matching)

Everything above is pattern-matchable in a diff. These are not — they require
actively trying to break the feature the way an attacker (or a pentester)
would, from the perspective of each actor below. Apply this whenever a change
adds or modifies an endpoint, queue handler, or anything reachable by an
external actor:

- **Unauthenticated actor**: What happens if every auth header is stripped
  from this request? Does it fail closed (401/403), or does a missing-auth
  code path silently fall through to a default?
- **Authenticated, wrong-tenant actor**: Swap the tenant/org ID in the request
  to one the actor doesn't belong to. Does authorization check tenant
  ownership, or only "is this ID's format valid"? (This is IDOR's SaaS-shaped
  sibling — see Enterprise SaaS section below.)
- **Authenticated, low-privilege actor**: Attempt every action a higher role
  can do. Does the check happen server-side, or only in UI conditional
  rendering?
- **Replay/idempotency actor**: Resend the same request/webhook twice. Does a
  side effect (charge, provisioning, alert) happen twice?
- **Malformed/oversized input actor**: Extremely long strings, deeply nested
  JSON, unexpected types (`null` for a required field, an array where an
  object is expected). Does it 500 with a stack trace (information
  disclosure), or fail with a clean validation error?
- **Timing/enumeration actor**: Does response time or error message differ
  between "resource doesn't exist" and "resource exists but you can't access
  it"? Either can leak information an attacker can enumerate against.

Findings from this section are usually 🔴/🟠 **Insecure Design** (OWASP A04) —
there's often no single bad line to point at, so state the scenario, the
actor, and the missing check explicitly rather than citing a line number.

---

## Security Gates — What Actually Blocks a Merge

Code review catches what a human or agent reads; these are the automated
gates that catch what reading a diff can miss (a vulnerable transitive
dependency, a secret that slipped past review, a container running as root).
A repo's CI should run all of these — if `robin-ai/.github/workflows-disabled/`
or an equivalent exists, treat its absence as an open finding, not silently
acceptable:

| Gate | Tooling examples | Blocks on |
|---|---|---|
| Secrets scanning | gitleaks, trufflehog, GitHub secret scanning | Any credential pattern from `[CG-CRED]` found in the diff or history |
| SAST | Semgrep, CodeQL | Injection/authn/authz patterns from this file found statically |
| Dependency / SCA scanning | `pip-audit`, `npm audit`, Dependabot, Snyk | Known CVEs at HIGH/CRITICAL severity in a direct or transitive dependency |
| Container image scanning | Trivy, Grype | CVEs in the base image; root user; missing `USER` directive |
| IaC scanning | checkov, tfsec, `kube-score` | Missing NetworkPolicy, privileged containers, overly broad RBAC (see `[CG-K8S-SEC]`) |
| DAST / periodic pentest | OWASP ZAP (automated), scheduled third-party pentest (manual) | Internet-facing surfaces only; cadence is a product/compliance decision, not a per-PR gate |

None of these replace the others — a clean SAST scan does not mean secrets
scanning or dependency scanning are redundant, and vice versa. If a repo is
missing one of these gates entirely, name that explicitly as a finding rather
than only reviewing what's in the diff.

---

## Enterprise SaaS Multi-Tenancy & Operational Security

Neeve's products are multi-tenant SaaS serving enterprise customers with
real building infrastructure behind them. These are the security properties
that matter specifically because of that shape, on top of everything above:

- **Tenant isolation is not the same check as ownership (IDOR).** IDOR asks
  "does user X own resource Y". Multi-tenancy asks "does resource Y belong to
  the same org/tenant as the authenticated session" — a query can pass an
  ownership check and still leak across tenants if `tenant_id`/`org_id`
  scoping is missing from the query itself. Every query against
  tenant-scoped data must filter by tenant ID derived from the authenticated
  session — never from a client-supplied field — as a WHERE clause, not an
  application-layer post-filter (post-filtering after an unscoped query still
  leaks via timing, error messages, or a missed code path).
- **Row-level security as defense in depth**: where the database supports it
  (e.g. Postgres RLS), tenant-scoping at the database layer catches the case
  where an application-layer scoping check is missed in one code path.
- **Per-tenant rate limiting / noisy-neighbor protection**: a rate limit
  keyed only by IP or global to the service lets one tenant degrade service
  for every other tenant. Rate limits on shared infrastructure should be
  keyed by tenant/org ID.
- **Webhook and integration security**: outbound webhooks to customer
  endpoints should be HMAC-signed so the customer can verify authenticity;
  inbound webhooks from third parties must verify the provider's signature
  before trusting the payload — an unverified inbound webhook is untrusted
  input like any other (see Injection rules above) and a fetch-back-to-a-URL
  from a webhook config is an SSRF vector (see above).
- **Least-privilege service credentials per integration**: a service account
  or API key used for one integration/tenant should not have blanket access
  to all tenants' data — scope credentials as narrowly as the integration
  needs, matching the zero-trust default in this repo's engineering
  principles.
- **Audit logging for compliance**: who did what, to which tenant's data,
  when — as an append-only/immutable trail, not just a debug log line. This
  is a customer-facing compliance requirement for enterprise buyers (SOC2 and
  similar), not just an internal nice-to-have — treat a missing audit trail
  on a sensitive action (role change, data export, credential rotation) as a
  finding, not a follow-up.
- **Secrets rotation and vault integration**: prefer short-lived credentials
  fetched from a secrets manager (Vault, cloud KMS) over long-lived static
  keys in config, and flag any new static long-lived credential as a
  candidate for rotation-capable storage instead.
- **Service-to-service auth (zero-trust internal traffic)**: internal
  service-to-service calls should authenticate (mTLS or service tokens), not
  rely on network position ("it's inside the VPC, so it's trusted") — this is
  the same zero-trust default from this repo's culture/ethos section, applied
  at the infrastructure level.
