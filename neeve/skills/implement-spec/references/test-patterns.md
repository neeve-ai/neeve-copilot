# Test Patterns Reference: Writing Tests That Prove Behaviour

## The Fundamental Test Question

Before writing any test, answer: **"What user journey breaks if this test fails?"**

If you cannot answer, you are writing an implementation test, not a behaviour test.
Implementation tests are fragile (break on refactors), give false confidence, and do not
prevent regressions.

---

## Test Anatomy: Required Elements

Every test method must have all three:

```python
async def test_outbox_worker_marks_row_failed_and_continues_on_permanent_fga_error(
    self,
    worker: OutboxWorker,
    mock_fga: AsyncMock,
    mock_db: AsyncMock,
) -> None:
    """
    FR-5: On permanent FGA error, row is marked failed and worker loop continues.
    UC-1: Enterprise org provisioned — tuple write fails permanently.
    Journey: A permanent FGA error must not crash the worker or silently drop
             subsequent rows. Other users' provisioning must succeed even when
             one row is permanently broken.
    """
    # Arrange — configure the boundary mock to represent the real failure
    permanent_error = FGAPermanentError("invalid tuple format")
    mock_fga.write.side_effect = permanent_error
    pending_rows = [make_pending_row(), make_pending_row()]  # two rows

    # Act
    await worker.process_batch(pending_rows)

    # Assert — both rows attempted, both marked failed, worker didn't raise
    assert mock_db.mark_failed.await_count == 2
    mock_db.mark_synced.assert_not_awaited()
```

The three required elements are:
1. **FR number + UC reference** in the docstring
2. **Journey line** — the user-facing consequence of failure
3. **Assertions on behaviour**, not on implementation (not "assert method X was called with Y
   args" — assert "the row has status=failed" or "the response was 403")

---

## The Four Test Classes

### HappyPath — correct output when everything works

```python
class TestPolicyEnforcerHappyPath:
    """Tests that verify the enforcer allows authorized requests."""

    async def test_allow_on_fga_permit(
        self,
        enforcer: PolicyEnforcer,
        mock_fga: AsyncMock,
        mock_redis: AsyncMock,
    ) -> None:
        """
        FR-12: Cache miss falls through to FGA Check; allow result cached.
        UC-3: viewer hits GET /policy/allowlist — should be permitted.
        Journey: Authorized users cannot access domain filter config if this fails.
        """
        mock_redis.get.return_value = None        # cache miss
        mock_fga.check.return_value = True        # FGA allows
        
        # Does not raise — is the observable outcome of "allow"
        await enforcer(relation="can_view_domain_filter", org_id=ORG_ID, user=viewer_user)
        
        mock_redis.setex.assert_awaited_once()    # result was cached
```

### FailurePaths — correct fail-closed / fail-open behaviour

```python
class TestPolicyEnforcerFailurePaths:
    """Tests fail-closed behaviour on dependency failures."""

    async def test_returns_503_when_fga_unreachable(
        self,
        enforcer: PolicyEnforcer,
        mock_fga: AsyncMock,
        mock_redis: AsyncMock,
    ) -> None:
        """
        FR-17: FGA unreachable → 503, no cache write.
        UC-N: Any user request during FGA outage.
        Journey: During FGA outage, system must not grant unauthorized access.
                 503 is correct; 200 would be a security incident.
        """
        mock_redis.get.return_value = None
        mock_fga.check.side_effect = FGAConnectionError("timeout")

        with pytest.raises(HTTPException) as exc_info:
            await enforcer(relation="can_view_domain_filter", org_id=ORG_ID, user=viewer_user)

        assert exc_info.value.status_code == 503
        mock_redis.setex.assert_not_awaited()  # no result cached from failed check

    async def test_falls_through_to_fga_when_redis_unavailable(
        self,
        enforcer: PolicyEnforcer,
        mock_fga: AsyncMock,
        mock_redis: AsyncMock,
    ) -> None:
        """
        FR-11: Redis unavailable → log WARN, fall through to FGA (not 503).
        Journey: Redis outage must not block authorized users. FGA is authoritative.
        """
        mock_redis.get.side_effect = RedisConnectionError("connection refused")
        mock_fga.check.return_value = True

        # Must not raise — Redis down is a cache miss, not a system failure
        await enforcer(relation="can_view_domain_filter", org_id=ORG_ID, user=viewer_user)

        mock_fga.check.assert_awaited_once()  # fell through to FGA
        mock_redis.setex.assert_not_awaited()  # no cache write on Redis error
```

### EdgeCases — derived from spec Edge Cases section

```python
class TestOutboxWorkerEdgeCases:
    """Tests derived from the Edge Cases section of the RBAC spec."""

    async def test_unknown_op_type_marked_failed_and_does_not_crash_loop(self, ...) -> None:
        """
        Edge case: rbac_outbox row has unknown op_type (outside CHECK constraint values).
        Journey: Manual ops fix inserts bad row — worker must not crash and must not
                 silently skip it (skipping could hide a write-path bug).
        """

    async def test_nats_failure_after_fga_write_leaves_row_pending(self, ...) -> None:
        """
        Edge case: FGA write succeeds but NATS publish times out.
        Invariant I-1: rbac.role_changed published only after FGA write succeeds.
        Journey: Retry on next poll must be safe — FGA Write of existing tuple is
                 idempotent (returns 200). Cache eviction is delayed but bounded.
        """

    async def test_concurrent_rows_for_same_user_applied_in_created_at_order(self, ...) -> None:
        """
        Edge case: Two role-change rows for same (org_id, user_id).
        Invariant I-3: Per-user ordering must be preserved.
        Journey: Role A → B → C must result in C in FGA. Out-of-order would leave B.
        """
```

### Regression — existing behaviour preserved

```python
class TestDomainFilterRouteRegression:
    """
    Existing routes that now have PolicyEnforcer wired.
    These tests must pass before the change AND after.
    """

    async def test_admin_can_still_put_policy_allowlist(
        self,
        client: AsyncClient,
        admin_jwt: str,
    ) -> None:
        """
        Regression: admin was previously authorized; PolicyEnforcer must not break this.
        Journey: Admins who manage domain filters would lose access — high-severity regression.
        """
        resp = await client.put(
            "/policy/allowlist",
            headers={"Authorization": f"Bearer {admin_jwt}"},
            json={"domains": ["example.com"]},
        )
        assert resp.status_code == 200
```

---

## Fixture Discipline

```python
# conftest.py — shared fixtures

@pytest.fixture
def mock_fga() -> AsyncMock:
    """
    Mock of the OpenFGA client protocol.
    Returns an AsyncMock configured with safe defaults (deny all).
    Tests that need allow behaviour override in the test body via parametrize.
    """
    mock = AsyncMock(spec=OpenFGAClientProtocol)
    mock.check.return_value = False  # default: deny
    mock.write.return_value = None
    return mock

@pytest.fixture
def mock_redis() -> AsyncMock:
    mock = AsyncMock(spec=RedisProtocol)
    mock.get.return_value = None  # default: cache miss
    return mock

@pytest.fixture
async def worker(mock_fga: AsyncMock, mock_db: AsyncMock, mock_nats: AsyncMock) -> OutboxWorker:
    return OutboxWorker(fga=mock_fga, db=mock_db, nats=mock_nats)
```

**Rules:**
- Fixtures return protocols/mocks, never concrete implementations
- Default mock state is the fail-safe (deny, miss, error) — tests that need success override
- `make_*` factory functions for building test data objects:

```python
def make_pending_row(
    op_type: str = "role_assignment",
    role: str = "viewer",
    old_role: str | None = None,
    org_id: str = "org_TEST",
    user_id: UUID | None = None,
) -> OutboxRow:
    """Factory for OutboxRow test objects. Keyword args make intent clear."""
    return OutboxRow(
        id=uuid4(),
        op_type=op_type,
        role=role,
        old_role=old_role,
        org_id=org_id,
        user_id=user_id or uuid4(),
        status="pending",
        created_at=datetime.now(UTC),
    )
```

---

## What Not To Test

These add coverage but prove nothing:

```python
# DO NOT TEST — trivial property access
def test_outbox_row_has_id(self, row: OutboxRow) -> None:
    assert row.id is not None  # proves the constructor ran, nothing more

# DO NOT TEST — mock was called (unless the call IS the contract)
def test_fga_write_called(self, worker, mock_fga) -> None:
    await worker.process(row)
    mock_fga.write.assert_called()  # tests wiring, not behaviour

# DO NOT TEST — internal state not visible to callers
def test_worker_sets_internal_flag(self, worker) -> None:
    worker.process(row)
    assert worker._processed_count == 1  # tests implementation detail

# DO NOT TEST — happy path with no assertion
def test_process_does_not_raise(self, worker) -> None:
    await worker.process(row)  # if this passes, what does it prove?
```

---

## Coverage That Matters

Coverage of these paths proves the most:

1. **Error propagation** — does the right exception type propagate with the right message?
2. **Fail-closed guarantees** — does failure return 503, not 200?
3. **Idempotency** — does a second call with the same data produce the same result?
4. **Ordering guarantees** — when order matters, does the implementation preserve it?
5. **Boundary validation** — are invalid inputs rejected at the right layer?
6. **Audit completeness** — is the audit log written before the response?
7. **Resource cleanup** — are connections/files/locks released on exception paths?

Coverage of these paths is noise:

- Getters and setters
- `__repr__` and `__str__`
- `dataclass` constructor calls
- Import-time constants
- `if __name__ == "__main__"` blocks
