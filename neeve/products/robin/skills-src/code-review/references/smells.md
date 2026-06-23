# Code Smells & Anti-Pattern Reference

## GOD Object Detection

A class is a GOD object if ANY of the following are true:
- More than 5 distinct responsibilities (SRP violation)
- More than 400 lines of code
- More than 15 public methods
- Imports from 8+ different modules
- Name ends in `Manager`, `Handler`, `Processor`, `Service`, `Utils`, `Helper` and has > 200 LOC

**When found:** List all responsibilities. Show how to split into 2-3 focused classes.

```python
# BAD — UserManager does auth, storage, email, billing
class UserManager:
    def authenticate(self): ...
    def save_to_db(self): ...
    def send_welcome_email(self): ...
    def charge_subscription(self): ...
    def generate_report(self): ...

# GOOD — each class owns one thing
class UserAuthenticator: ...
class UserRepository: ...
class UserNotifier: ...
```

---

## Additive / Dead Code

**Flag:**
- Commented-out code blocks older than one commit (use git, not comments)
- Feature flags hardcoded to `True` with no path where they're `False`
- Functions defined but never called (check imports and usages)
- Import statements for unused modules
- `else: pass` or `except: pass` blocks
- Code guarded by `if False:` or `if 0:`

---

## Duplication

**Flag when the same logic appears 2+ times:**
- Copy-paste with variable name changes only
- Same validation logic in multiple endpoints
- Same error handling pattern repeated inline instead of in a decorator

**Fix approach:** Extract to a shared utility, decorator, or base class. Show the refactor.

---

## Test Quality Anti-Patterns

### Mock abuse
```python
# BAD — mocking the thing under test
@patch("myapp.services.payment.StripeClient")
def test_charge(mock_stripe):
    mock_stripe.charge.return_value = Mock(status="success")
    result = PaymentService().charge(100)
    assert result.status == "success"  # you're testing your mock, not your code
```

```python
# GOOD — mock the external boundary, test the behavior
@patch("myapp.clients.stripe.requests.post")
def test_charge_success(mock_post):
    mock_post.return_value.json.return_value = {"id": "ch_123", "status": "succeeded"}
    result = PaymentService().charge(amount=100, currency="usd")
    assert result.charge_id == "ch_123"
    assert result.success is True
```

### Assertion-free tests
```python
# CRITICAL — this test proves nothing
def test_process():
    processor.process(data)   # no assertion
```

### Implementation-testing tests
```python
# BAD — tests internals, breaks on refactor
def test_uses_redis():
    svc = CacheService()
    svc.get("key")
    assert svc._redis_client.get.called   # internal

# GOOD — tests behavior
def test_returns_cached_value():
    svc = CacheService()
    svc.set("key", "value")
    assert svc.get("key") == "value"
```

### Missing edge cases checklist (for every non-trivial function)
- [ ] Empty input (`""`, `[]`, `{}`, `None`)
- [ ] Single-element collection
- [ ] Maximum boundary value
- [ ] Negative numbers where domain allows positives only
- [ ] Concurrent callers (if the code touches shared state)
- [ ] Partial failure mid-operation (transaction rollback)

---

## Python-Specific Smells

### Mutable default arguments
```python
# CRITICAL — shared across all calls
def append_item(item, lst=[]):
    lst.append(item)
    return lst

# CORRECT
def append_item(item, lst=None):
    if lst is None:
        lst = []
    lst.append(item)
    return lst
```

### Bare except
```python
# HIGH — swallows KeyboardInterrupt, SystemExit, everything
try:
    do_thing()
except:
    pass

# CORRECT
try:
    do_thing()
except (ValueError, RuntimeError) as e:
    log.warning("thing failed", error=str(e))
```

### String concatenation in loop
```python
# MEDIUM — O(n²) allocations
result = ""
for item in items:
    result += str(item)

# CORRECT
result = "".join(str(item) for item in items)
```

### N+1 query
```python
# CRITICAL in prod — 1000 users = 1001 queries
users = db.query(User).all()
for user in users:
    orders = db.query(Order).filter_by(user_id=user.id).all()

# CORRECT — single join
users = db.query(User).options(joinedload(User.orders)).all()
```

### Wrong data structure for use case
```python
# MEDIUM — O(n) membership test in a list
VALID_STATUSES = ["active", "pending", "closed"]
if status in VALID_STATUSES:   # O(n)

# CORRECT — O(1) with set
VALID_STATUSES = {"active", "pending", "closed"}
if status in VALID_STATUSES:

# MEDIUM — plain dict where defaultdict fits
counts = {}
for item in items:
    if item not in counts:
        counts[item] = 0
    counts[item] += 1

# CORRECT
from collections import defaultdict
counts = defaultdict(int)
for item in items:
    counts[item] += 1
```
