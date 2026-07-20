# Kubernetes & Production Deployment Reference

## Graceful Shutdown

Every long-running process MUST handle SIGTERM. The standard pattern:

```python
import signal, sys, asyncio

shutdown_event = asyncio.Event()

def _handle_sigterm(signum, frame):
    shutdown_event.set()

signal.signal(signal.SIGTERM, _handle_sigterm)
signal.signal(signal.SIGINT, _handle_sigterm)

async def main():
    server = await start_server()
    await shutdown_event.wait()
    await server.shutdown(grace_period=30)
    sys.exit(0)
```

**Flag if:** No signal handler, `sys.exit()` called directly in response to a request, blocking
shutdown (no timeout), or `atexit` used as the sole shutdown mechanism.

---

## Health Endpoints

### Required pattern
```python
@app.get("/healthz/live")    # Liveness: is the process alive?
async def liveness():
    return {"status": "ok"}  # NEVER call downstream here

@app.get("/healthz/ready")   # Readiness: can we serve traffic?
async def readiness():
    try:
        await db.ping()      # One cheap downstream check is acceptable
        return {"status": "ok"}
    except Exception:
        raise HTTPException(503, "not ready")
```

**Flag if:**
- Single `/health` endpoint used for both (k8s needs them separate)
- Liveness probe calls downstream — one slow DB → crash loop
- No `/healthz` at all
- Readiness always returns 200 even during startup

---

## Probes in Deployment YAML

```yaml
livenessProbe:
  httpGet:
    path: /healthz/live
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /healthz/ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3

startupProbe:           # Required for slow-starting apps
  httpGet:
    path: /healthz/live
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

**Flag if:** `initialDelaySeconds` is the only startup guard (fragile), no `startupProbe` on apps
with DB migrations or slow init, `failureThreshold: 1` (too aggressive).

---

## Resource Requests & Limits

**Flag if:**
- No `resources.requests` → pod gets no guaranteed CPU/memory, evicted first
- No `resources.limits` → noisy neighbor risk
- `limits.cpu` much higher than `requests.cpu` → throttling
- Memory limit equals request (fine) vs limit >> request (risk OOMKill)

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"
```

---

## Secrets & Configuration

**CRITICAL flags:**
- Secret values in environment variable literals in YAML (use `secretKeyRef`)
- Secrets in ConfigMaps (wrong resource type)
- Secrets committed to source control
- `os.environ.get("SECRET")` with no fallback raises in prod; with `None` default silently breaks logic

**Correct pattern:**
```yaml
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: app-secrets
        key: db-password
```

---

## Logging

**Flag if:**
- `print()` used instead of `logging` or structlog
- Logging to a file path (breaks stdout/stderr aggregation)
- Unstructured log strings (can't query in Loki/Datadog)
- No log level configuration via env var
- No request ID / correlation ID threaded through log entries
- PII logged (email, IP, token)

**Required pattern:**
```python
import structlog
log = structlog.get_logger()

log.info("order.created", order_id=order.id, user_id=user.id, amount=order.total)
```

---

## Observability (Metrics)

**Flag if:**
- No `/metrics` Prometheus endpoint
- No counter on every error path
- No histogram on external call latency
- Business-critical operations (payment, auth) have no metric

```python
from prometheus_client import Counter, Histogram

REQUEST_COUNT = Counter("http_requests_total", "Total HTTP requests", ["method", "endpoint", "status"])
REQUEST_LATENCY = Histogram("http_request_duration_seconds", "HTTP request latency", ["endpoint"])
```

---

## Container Image

**Flag if:**
- Image tag is `latest` (non-deterministic deploys)
- No image digest pinning in production manifests
- Running as root (missing `securityContext.runAsNonRoot: true`)
- No `readOnlyRootFilesystem: true`
- Secrets baked into image layers

---

## PodDisruptionBudget

Required for any stateful service or service with <3 replicas in HA deployment.

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: my-app
```

---

## Common Crash Loop Causes (flag proactively)

1. DB migration runs synchronously on startup before readiness — blocks ready state
2. Missing required env var → `KeyError` at import time → crash before probe fires
3. Port conflict — hardcoded port already in use
4. Infinite retry loop with no backoff → CPU spike → OOMKill
5. Uncaught exception in asyncio event loop kills entire process
