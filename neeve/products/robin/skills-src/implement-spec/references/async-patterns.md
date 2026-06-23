# Async Patterns Reference

## The Async Mental Model

asyncio is cooperative multitasking. A coroutine runs until it hits an `await`, at which point
the event loop can run another coroutine. This means:

- **CPU-bound work blocks the event loop.** Offload to `asyncio.run_in_executor` (thread pool)
  or `ProcessPoolExecutor` for true parallelism.
- **Every `await` is a potential interleaving point.** Shared mutable state accessed across
  `await` points without a lock is a race condition.
- **Cancellation propagates.** When a task is cancelled, `CancelledError` is raised at the next
  `await`. Always clean up in `finally` blocks.

---

## Background Worker Pattern (correct implementation)

```python
"""
Application layer — background worker base.
Implements the lifecycle pattern for all long-running background tasks.
"""
import asyncio
import signal
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager
from typing import NoReturn

import structlog

log = structlog.get_logger()


class BackgroundWorker:
    """
    Single-responsibility: manages the lifecycle of a polling loop.
    Subclass must implement `_process_batch()`.
    
    SOLID — O: new polling behaviours extend this class, not modify it.
    SOLID — D: dependencies injected, not imported.
    """

    def __init__(self, poll_interval_seconds: int = 5) -> None:
        self._poll_interval = poll_interval_seconds
        self._shutdown = asyncio.Event()

    async def run(self) -> NoReturn:
        """Main loop. Runs until shutdown is signalled."""
        log.info("worker.started", worker=type(self).__name__)
        try:
            while not self._shutdown.is_set():
                try:
                    await self._process_batch()
                except Exception:
                    log.exception("worker.batch_failed", worker=type(self).__name__)
                    # Never crash the loop on a single batch failure
                await asyncio.sleep(self._poll_interval)
        finally:
            log.info("worker.stopped", worker=type(self).__name__)

    async def stop(self) -> None:
        self._shutdown.set()

    async def _process_batch(self) -> None:
        raise NotImplementedError


@asynccontextmanager
async def managed_worker(
    worker: BackgroundWorker,
) -> AsyncGenerator[BackgroundWorker, None]:
    """Context manager that starts a worker task and cancels it on exit."""
    task = asyncio.create_task(worker.run(), name=type(worker).__name__)
    try:
        yield worker
    finally:
        await worker.stop()
        task.cancel()
        try:
            await task
        except asyncio.CancelledError:
            pass
```

---

## SIGTERM Handling (Kubernetes-correct)

```python
# app/main.py — FastAPI lifespan pattern
from contextlib import asynccontextmanager
from fastapi import FastAPI

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    worker = OutboxWorker(fga_client=fga, db=db, nats=nats)
    task = asyncio.create_task(worker.run())
    
    yield  # Application runs
    
    # Shutdown (SIGTERM triggers this path via uvicorn)
    await worker.stop()
    task.cancel()
    try:
        await asyncio.wait_for(task, timeout=30.0)  # grace period
    except (asyncio.CancelledError, asyncio.TimeoutError):
        pass

app = FastAPI(lifespan=lifespan)
```

---

## Shared State and Locks

```python
# WRONG — race condition: two concurrent tasks can interleave at await
class MetricsCollector:
    def __init__(self) -> None:
        self._count = 0

    async def increment(self) -> None:
        current = self._count      # read
        await asyncio.sleep(0)     # yield — another task can run here
        self._count = current + 1  # write with stale value

# CORRECT — lock prevents interleaving
class MetricsCollector:
    def __init__(self) -> None:
        self._count = 0
        self._lock = asyncio.Lock()

    async def increment(self) -> None:
        async with self._lock:
            self._count += 1
```

---

## Async Database Patterns

```python
# CORRECT — session per unit of work, not per request or process
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

class OutboxWorker:
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory  # injected

    async def _process_batch(self) -> None:
        async with self._session_factory() as session:
            async with session.begin():  # transaction scoped to batch
                rows = await self._fetch_pending(session)
                for row in rows:
                    await self._process_row(session, row)
                # commit happens at end of `with session.begin()` block
```

### SELECT FOR UPDATE SKIP LOCKED (correct pattern)

```python
from sqlalchemy import select, update
from sqlalchemy.dialects.postgresql import insert

async def fetch_pending_rows(
    session: AsyncSession,
    limit: int = 50,
) -> list[OutboxRow]:
    result = await session.execute(
        select(OutboxRow)
        .where(OutboxRow.status == "pending")
        .order_by(OutboxRow.org_id, OutboxRow.user_id, OutboxRow.created_at)
        .limit(limit)
        .with_for_update(skip_locked=True)  # concurrent workers skip locked rows
    )
    return list(result.scalars().all())
```

---

## Timeout and Retry Patterns

```python
# External call with timeout — always required
import httpx
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
    before_sleep_log,
)
import logging

@retry(
    retry=retry_if_exception_type((httpx.TimeoutException, httpx.HTTPStatusError)),
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=1, max=10),
    before_sleep=before_sleep_log(logging.getLogger(__name__), logging.WARNING),
    reraise=True,
)
async def call_external(client: httpx.AsyncClient, url: str, payload: dict) -> dict:
    resp = await client.post(url, json=payload, timeout=5.0)
    resp.raise_for_status()
    return resp.json()
```

---

## asyncio.gather vs sequential await

```python
# Sequential — second call waits for first (correct when ordering matters)
result_a = await fetch_a()
result_b = await fetch_b(result_a)  # depends on a

# Concurrent — both calls run in parallel (correct when independent)
result_a, result_b = await asyncio.gather(fetch_a(), fetch_b())

# Concurrent with error handling — one failure doesn't cancel others
results = await asyncio.gather(fetch_a(), fetch_b(), return_exceptions=True)
for result in results:
    if isinstance(result, Exception):
        log.error("fetch_failed", error=str(result))
```

---

## NATS JetStream Publish (correct pattern)

```python
# CORRECT — JetStream publish with ack, not fire-and-forget core NATS
import json
import nats
from nats.js.errors import NoStreamResponseError

async def publish_role_changed(
    js: nats.js.JetStreamContext,
    org_id: str,
    user_id: str,
) -> None:
    payload = json.dumps({
        "event": "rbac.role_changed",
        "org_id": org_id,
        "user_id": user_id,
    }).encode()
    
    try:
        ack = await js.publish("rbac.role_changed", payload)
        # ack.seq confirms delivery to the stream — wait for it
    except NoStreamResponseError:
        raise  # let caller decide: row stays pending, will retry
```

---

## asyncio Task Leak Prevention

```python
# WRONG — task is created but never awaited or stored; garbage collected
async def fire_background_work() -> None:
    asyncio.create_task(some_coroutine())  # leaked if not stored

# CORRECT — store task reference; cancel on shutdown
class Service:
    def __init__(self) -> None:
        self._background_tasks: set[asyncio.Task] = set()

    def schedule(self, coro) -> None:
        task = asyncio.create_task(coro)
        self._background_tasks.add(task)
        task.add_done_callback(self._background_tasks.discard)

    async def shutdown(self) -> None:
        for task in list(self._background_tasks):
            task.cancel()
        await asyncio.gather(*self._background_tasks, return_exceptions=True)
```

---

## FastAPI BackgroundTasks (correct injection)

```python
# WRONG — detached instance; tasks never run
async def endpoint(body: RequestBody) -> Response:
    bg = BackgroundTasks()           # not the request-scoped instance
    bg.add_task(write_audit, ...)    # silently dropped

# CORRECT — FastAPI injects the request-scoped instance automatically
from fastapi import BackgroundTasks, Depends

class PolicyEnforcer:
    async def __call__(
        self,
        background_tasks: BackgroundTasks,  # FastAPI resolves this
        user: CurrentUser = Depends(get_current_user),
    ) -> None:
        ...
        if allow and _sample(ALLOW_SAMPLE_RATE):
            background_tasks.add_task(write_audit_log, ...)
```
