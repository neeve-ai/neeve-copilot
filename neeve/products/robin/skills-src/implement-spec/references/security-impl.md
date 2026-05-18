# Security Implementation Reference

## The Implementation Security Protocol

Run this mentally before touching any file that handles:
auth · data access · logging · external calls · inter-service messaging · user input

---

## Input Validation: Boundary Pattern

Validate at the entry boundary — once, explicitly, with an allow-list.

```python
# domain/value_objects.py
from dataclasses import dataclass
import re

VALID_ROLES: frozenset[str] = frozenset({"viewer", "operator", "admin", "super_admin"})

@dataclass(frozen=True)
class Role:
    value: str

    def __post_init__(self) -> None:
        if self.value not in VALID_ROLES:
            raise ValueError(f"Unknown role: {self.value!r}. Valid: {VALID_ROLES}")

@dataclass(frozen=True)
class OrgId:
    value: str
    _PATTERN: ClassVar[re.Pattern] = re.compile(r"^org_[A-Za-z0-9]{16}$")

    def __post_init__(self) -> None:
        if not self._PATTERN.match(self.value):
            raise ValueError(f"Invalid org_id format: {self.value!r}")
```

**Rule:** Business logic receives value objects, never raw strings. Route handlers parse and
validate; domain objects enforce invariants.

---

## Authentication: Constant-Time Comparison

```python
import hmac
import secrets

# WRONG — timing oracle: short-circuits on first mismatch
def verify_token(provided: str, expected: str) -> bool:
    return provided == expected

# CORRECT — constant time regardless of where strings diverge
def verify_token(provided: str, expected: str) -> bool:
    return hmac.compare_digest(
        provided.encode("utf-8"),
        expected.encode("utf-8"),
    )

# Token generation — always CSPRNG
def generate_reset_token() -> str:
    return secrets.token_urlsafe(32)  # 32 bytes = 256 bits entropy
```

---

## JWT: Algorithm Pinning

```python
import jwt

# CRITICAL — no algorithms= parameter accepts alg:none
decoded = jwt.decode(token, key)   # NEVER

# CORRECT — explicit algorithm list, reject none
decoded = jwt.decode(
    token,
    key,
    algorithms=["HS256"],     # or ["RS256"] for asymmetric
    options={"require": ["exp", "iat", "iss", "aud"]},
)
```

---

## Database: Parameterized Queries Always

```python
# CRITICAL — string formatting into SQL
query = f"SELECT * FROM users WHERE org_id = '{org_id}'"  # SQLi

# CORRECT — SQLAlchemy ORM (always parameterized)
result = await session.execute(
    select(User).where(User.org_id == org_id)  # parameterized
)

# CORRECT — raw SQL with explicit params (never format strings)
result = await session.execute(
    text("SELECT * FROM users WHERE org_id = :org_id"),
    {"org_id": org_id},
)
```

---

## Secrets: Injection Pattern

```python
# CRITICAL — default value is a secret in source control
API_KEY = os.environ.get("API_KEY", "dev-secret-12345")

# CRITICAL — secret logged
log.info(f"Connecting with key: {api_key}")

# CORRECT — required env var (raises on missing, never defaults)
API_KEY: str = os.environ["API_KEY"]  # KeyError is intentional at startup

# CORRECT — secrets in pydantic settings with validation
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    api_key: str        # required, no default
    db_url: str         # required, no default
    debug: bool = False  # optional with safe default

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
```

---

## Logging: PII Firewall

Before every `log.*()` call, scan the interpolated values for:
- Email addresses
- IP addresses (log hash, not raw IP)
- Names, phone numbers, SSNs
- Tokens, passwords, API keys
- UUIDs that are Auth0 subs or external identifiers (use internal UUIDs)

```python
import hashlib
import structlog

log = structlog.get_logger()

# WRONG — PII in log
log.info("user_logged_in", email=user.email, ip=request.client.host)

# CORRECT — internal ID and hashed IP
log.info(
    "auth.login_success",
    user_id=str(user.id),              # internal UUID only
    ip_hash=hashlib.sha256(           # hashed, not raw
        request.client.host.encode()
    ).hexdigest()[:16],
    request_id=request.headers.get("X-Request-ID"),
)
```

---

## Authorization: IDOR Prevention

Every resource access must scope to the current actor:

```python
# CRITICAL — IDOR: user supplies org_id and gets any org's data
async def get_policy(org_id: str, current_user: User) -> Policy:
    return await policy_repo.get(org_id)  # no ownership check

# CORRECT — scope to actor's org
async def get_policy(current_user: User) -> Policy:
    # org_id comes from the authenticated user, not the request
    policy = await policy_repo.get(current_user.org_id)
    if policy is None:
        raise HTTPException(404)  # not 403 — avoids confirming existence to other orgs
    return policy
```

---

## Fail-Closed Implementation

Document the failure mode of every dependency:

```python
class PolicyEnforcer:
    """
    Fail-closed model:
    - Redis unavailable → cache miss → fall through to FGA (not 503)
    - FGA unavailable → 503 (not 200) — authorization source is down
    - FGA denies → 403 → audit written synchronously before response
    """

    async def __call__(self, relation: str, ...) -> None:
        # Try cache
        cached = None
        try:
            cached = await self._redis.get(self._cache_key(relation))
        except RedisError:
            log.warning("enforcer.redis_unavailable", request_id=..., error=...)
            # Fall through — Redis is performance cache, not authorization source

        if cached == "deny":
            await self._write_audit(decision="deny")  # synchronous
            raise HTTPException(403, detail=self._denied_body(relation))
        if cached == "allow":
            return

        # Cache miss or Redis down — always check FGA
        try:
            allowed = await self._fga.check(...)
        except FGAError:
            log.error("enforcer.fga_unavailable", ...)
            raise HTTPException(503)  # fail closed — never grant on FGA error

        await self._redis.setex(self._cache_key(relation), 60, "allow" if allowed else "deny")

        if not allowed:
            await self._write_audit(decision="deny")  # before response
            raise HTTPException(403, detail=self._denied_body(relation))
```

---

## Structured Error Responses

Never leak internal state in HTTP error responses:

```python
# WRONG — leaks internal FGA error payload and stack trace
raise HTTPException(403, detail={"fga_error": str(fga_error), "traceback": ...})

# CORRECT — structured, client-useful, internals-free
raise HTTPException(
    status_code=403,
    detail={
        "error": "rbac_denied",
        "role": role,          # useful for client-side messaging
        "resource": resource,
        "action": action,
    },
)
# Exception handler in main.py ensures this is the top-level response body, not nested under "detail"
```

---

## Audit Log: Synchronous for Deny, Async for Allow

```python
# Deny audit — must complete before 403 is returned (security control)
async def _write_deny_audit(self, ...) -> None:
    await self._audit_repo.insert(AuditEvent(decision="deny", ...))  # awaited
    raise HTTPException(403, ...)  # only reached after audit write

# Allow audit — sampled, backgrounded (UX convenience, not security)
def _schedule_allow_audit(self, background_tasks: BackgroundTasks, ...) -> None:
    if random.random() < self._allow_sample_rate:
        background_tasks.add_task(
            self._audit_repo.insert,
            AuditEvent(decision="allow", ...),
        )
```

---

## Supply Chain: Dependency Hygiene in Code

```python
# pyproject.toml — always pinned
[tool.poetry.dependencies]
python = "^3.11"
fastapi = "==0.115.0"      # pinned, not >=
sqlalchemy = "==2.0.36"    # pinned

# requirements.txt — always with hashes
# Generate with: pip-compile --generate-hashes requirements.in
fastapi==0.115.0 \
    --hash=sha256:abc123... \
    --hash=sha256:def456...
```

When adding a new dependency, state:
1. Why no stdlib or existing dependency covers this need
2. The license
3. The CVE status (check PyPI safety / npm audit)
4. Whether it adds transitive dependencies
