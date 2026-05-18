# Testing Reference: Patterns, Coverage, and TDD Discipline

## TDD Discipline

The spec drives the tests. The tests drive the tasks. This is the order:

1. Read the use cases and functional requirements
2. Derive the test IDs (T-01, T-02, ...) from each use case
3. Write the test *signatures* (what they mock, what they assert) in the Required Tests section
4. Write the implementation tasks that make those tests pass

Never write a task without a corresponding test. Never write a test without a tracing FR number.

---

## Coverage Thresholds

| New file type | Minimum coverage |
|--------------|-----------------|
| Core business logic | 95% |
| Repository / data access | 95% |
| Infrastructure adapters | 95% |
| FastAPI route handlers | 95% |
| Background workers | 95% (failure paths are critical) |
| Frontend components | 95% line, 95% branch |
| Utility / helpers | 95% |

**Never count `__init__.py`, migrations, or generated code toward coverage.**

---

## Python Test Patterns

### Unit test structure (pytest)

```python
# test_[module].py
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from [module] import [Component]

class TestComponentHappyPath:
    """Tests that verify the component does the right thing when everything works."""

    @pytest.fixture
    def mock_dependency(self) -> AsyncMock:
        """Return a configured mock of [Dependency]."""
        mock = AsyncMock()
        mock.some_method.return_value = expected_value
        return mock

    @pytest.fixture
    def component(self, mock_dependency: AsyncMock) -> Component:
        return Component(dependency=mock_dependency)  # injected, never instantiated inside

    async def test_[use_case]_returns_[expected](
        self,
        component: Component,
        mock_dependency: AsyncMock,
    ) -> None:
        # Arrange
        input_data = ...
        expected = ...

        # Act
        result = await component.method(input_data)

        # Assert
        assert result == expected
        mock_dependency.some_method.assert_awaited_once_with(...)


class TestComponentFailurePaths:
    """Tests that verify fail-closed behaviour on error conditions."""

    async def test_raises_on_[error_condition](self, component: Component) -> None:
        with pytest.raises(ExpectedError, match="descriptive message"):
            await component.method(bad_input)
```

### FastAPI route tests

```python
from httpx import AsyncClient
import pytest

@pytest.fixture
async def client(app: FastAPI) -> AsyncGenerator[AsyncClient, None]:
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

async def test_[route]_returns_403_for_[role](client: AsyncClient, jwt_for: callable) -> None:
    headers = {"Authorization": f"Bearer {jwt_for(role='viewer')}"}
    resp = await client.put("/policy/allowlist", headers=headers, json={...})
    assert resp.status_code == 403
    body = resp.json()
    assert body["error"] == "rbac_denied"
    assert body["role"] == "viewer"
    assert "detail" not in body  # not nested — flat response body
```

### Background worker tests

```python
# Workers have critical failure paths — test every branch
async def test_worker_marks_failed_on_permanent_fga_error(
    worker: OutboxWorker,
    mock_fga: AsyncMock,
    mock_db: AsyncMock,
) -> None:
    mock_fga.write.side_effect = PermanentFGAError("invalid tuple")
    await worker.process_batch([pending_row])
    mock_db.mark_failed.assert_awaited_once_with(pending_row.id)
    # Worker must NOT crash — verify it continues
    mock_db.mark_failed.assert_awaited_once()  # only one row, one call

async def test_worker_retries_on_transient_error(
    worker: OutboxWorker,
    mock_fga: AsyncMock,
) -> None:
    mock_fga.write.side_effect = TransientFGAError("503")
    await worker.process_batch([pending_row])
    # Row stays pending — no mark_synced, no mark_failed
    mock_db.mark_synced.assert_not_awaited()
    mock_db.mark_failed.assert_not_awaited()
```

### Async test configuration

```toml
# pyproject.toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
asyncio_default_fixture_loop_scope = "function"

[tool.coverage.run]
omit = ["*/migrations/*", "*/__init__.py", "*/conftest.py"]

[tool.coverage.report]
fail_under = 95
show_missing = true
```

---

## TypeScript / Frontend Test Patterns

### Component tests (React Testing Library)

```typescript
// [Component].test.tsx
import { render, screen, userEvent } from '@testing-library/react'
import { [Component] } from './[Component]'

describe('[Component]', () => {
  it('renders [expected state] when [condition]', () => {
    render(<Component prop="value" />)
    expect(screen.getByRole('button', { name: /submit/i })).toBeInTheDocument()
  })

  it('calls [handler] with [expected args] when [user action]', async () => {
    const onSubmit = vi.fn()
    render(<Component onSubmit={onSubmit} />)
    await userEvent.click(screen.getByRole('button', { name: /submit/i }))
    expect(onSubmit).toHaveBeenCalledWith(expectedArgs)
  })

  it('shows [error state] when [action fails]', async () => {
    // Test error boundaries, loading states, empty states
  })
})
```

### API / service unit tests

```typescript
// [service].test.ts
import { http, HttpResponse } from 'msw'
import { setupServer } from 'msw/node'

const server = setupServer(
  http.get('/api/resource', () => HttpResponse.json(mockData))
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

it('returns [expected] when API call succeeds', async () => {
  const result = await fetchResource(id)
  expect(result).toMatchObject(expectedShape)
})

it('throws [error] when API returns 403', async () => {
  server.use(http.get('/api/resource', () => new HttpResponse(null, { status: 403 })))
  await expect(fetchResource(id)).rejects.toThrow(AuthorizationError)
})
```

---

## Integration Test Patterns

### What requires a real database/service vs. a mock

| Dependency | In unit tests | In integration tests |
|-----------|--------------|---------------------|
| PostgreSQL | `AsyncMock` | Real test DB (testcontainers or fixture DB) |
| Redis | `AsyncMock` | Real Redis (testcontainers) |
| OpenFGA | `AsyncMock` | Real FGA store or HTTP double |
| NATS | `AsyncMock` | Real NATS or in-process mock |
| External APIs | `AsyncMock` or `responses` | msw / httpretty / VCR |

### Integration test structure

```python
@pytest.mark.integration
async def test_full_round_trip(
    db: AsyncSession,
    redis: Redis,
    fga_store: FGATestStore,
    nats: NATSClient,
) -> None:
    # Arrange — insert the triggering DB row
    await db.execute(insert(rbac_outbox).values(pending_row))
    await db.commit()

    # Act — run the worker
    await worker.poll()

    # Assert — verify the FGA tuple was written
    assert await fga_store.check(user_id, "can_view", org_id)

    # Assert — verify the NATS event was published
    msg = await nats.subscribe("rbac.role_changed").next(timeout=1.0)
    payload = json.loads(msg.data)
    assert payload["user_id"] == str(user_id)
```

---

## Test Naming Conventions

Good test names read as a sentence:

```
test_[subject]_[action]_[expected_outcome]_when_[condition]

# Examples:
test_outbox_worker_marks_row_failed_when_fga_returns_permanent_error
test_policy_enforcer_returns_503_when_openfga_unreachable
test_policy_enforcer_skips_cache_write_when_redis_unavailable
test_charge_deduplicates_when_idempotency_key_already_exists
```

Avoid:
- `test_happy_path` — not descriptive
- `test_1`, `test_2` — useless
- `test_it_works` — proves nothing

---

## Regression Test Pattern

For every spec that modifies existing behaviour, include an explicit regression section:

```python
class TestRegressions:
    """
    Verifies that existing behaviour is preserved after this change.
    Each test corresponds to a previously-passing scenario.
    """

    async def test_existing_[feature]_still_[behaviour](self, ...) -> None:
        # This behaviour existed before the change and must continue to work
        ...
```
