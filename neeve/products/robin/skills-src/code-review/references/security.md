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
