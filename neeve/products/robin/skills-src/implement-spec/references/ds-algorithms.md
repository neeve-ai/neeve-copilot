# Data Structures & Algorithms Reference

## The Selection Framework

Before choosing a data structure, answer three questions:
1. **What is the dominant access pattern?** (lookup, insert, delete, iterate, membership, range query)
2. **What is the expected data size?** (10s, 1000s, millions)
3. **What is the acceptable worst-case complexity?** (O(1), O(log n), O(n), never O(n²) in hot paths)

Then choose the structure that satisfies all three. Never default to `list` or `dict` without this
reasoning. The wrong structure at 10 items is invisible; at 10,000 it degrades; at 10M it pages.

---

## Python Structure Selection Matrix

| Access pattern | Best structure | Avoid | Why |
|---------------|----------------|-------|-----|
| Membership test | `set` / `frozenset` | `list` | O(1) vs O(n) |
| Ordered membership | `dict` (insertion-ordered 3.7+) | `list` + `in` | O(1) lookup, O(1) order |
| Deduplication preserving order | `dict.fromkeys(iterable)` | `list` + `seen` set | single pass |
| Top-N items | `heapq.nlargest(n, iterable)` | `sorted()[:-n]` | O(n log k) vs O(n log n) |
| Min/max access | `heapq` | `sorted` list re-sorted | O(log n) push/pop vs O(n log n) |
| Sliding window | `collections.deque(maxlen=N)` | `list` + slice | O(1) append/popleft |
| Frequency count | `collections.Counter` | manual dict | optimized C impl |
| Default value dict | `collections.defaultdict` | `dict.setdefault` | cleaner, faster |
| Ordered by key | `collections.OrderedDict` | `dict` + sort | explicit ordering |
| Bidirectional lookup | two dicts | one dict + iteration | O(1) both directions |
| Sorted insertions | `sortedcontainers.SortedList` | `list` + `bisect` | maintained sort |
| Interval queries | `sortedcontainers.SortedList` | nested loops | O(log n) range |
| LRU cache | `functools.lru_cache` / `cachetools.LRUCache` | manual dict | eviction built-in |
| FIFO queue | `collections.deque` | `list` (pop(0) is O(n)) | O(1) both ends |
| Immutable record | `dataclasses(frozen=True)` / `NamedTuple` | plain tuple | named access, type-safe |
| Config/flags | `dataclasses(frozen=True)` | `dict` | type-checked, IDE-complete |

---

## Common Complexity Traps

### The O(n²) list membership trap
```python
# WRONG — O(n²): `in` on a list is O(n), called n times
results = []
for item in large_list:
    if item in another_large_list:  # O(n) per iteration
        results.append(item)

# CORRECT — O(n): convert to set once, then O(1) membership
lookup = set(another_large_list)   # O(n) once
results = [item for item in large_list if item in lookup]  # O(n) total
```

### The repeated sort trap
```python
# WRONG — O(n log n) per insertion
items = []
items.append(new_item)
items.sort()  # called every time

# CORRECT — O(log n) per insertion
import heapq
items = []
heapq.heappush(items, new_item)  # maintained heap
smallest = heapq.heappop(items)  # O(log n)
```

### The string concatenation trap
```python
# WRONG — O(n²): each += allocates a new string
result = ""
for chunk in chunks:
    result += chunk

# CORRECT — O(n): single allocation at join
result = "".join(chunks)
```

### The nested dict update trap
```python
# WRONG — O(n) per lookup when default-building a dict-of-lists
groups: dict[str, list] = {}
for item in items:
    if item.key not in groups:
        groups[item.key] = []
    groups[item.key].append(item)

# CORRECT — O(1) amortized
from collections import defaultdict
groups: defaultdict[str, list] = defaultdict(list)
for item in items:
    groups[item.key].append(item)
```

### The re-computation trap
```python
# WRONG — recomputes expensive value on every call
def get_threshold(config: Config) -> float:
    return sum(config.weights) / len(config.weights)  # O(n) every call

# CORRECT — compute once, cache result
from functools import cached_property
class Config:
    @cached_property
    def threshold(self) -> float:
        return sum(self.weights) / len(self.weights)  # O(n) once
```

---

## Algorithm Patterns

### Early termination
When searching for any match, use `any()` / `next()` / `for...break` — never collect all results
and check length:
```python
# WRONG — evaluates entire generator
has_admin = len([u for u in users if u.role == "admin"]) > 0

# CORRECT — short-circuits on first match
has_admin = any(u.role == "admin" for u in users)
```

### Two-pointer / sliding window
For contiguous range problems on sorted data, avoid nested loops:
```python
# Finding pairs that sum to target — O(n) not O(n²)
def find_pair(nums: list[int], target: int) -> tuple[int, int] | None:
    nums.sort()
    left, right = 0, len(nums) - 1
    while left < right:
        total = nums[left] + nums[right]
        if total == target:
            return nums[left], nums[right]
        elif total < target:
            left += 1
        else:
            right -= 1
    return None
```

### Memoization
For recursive functions with overlapping subproblems, apply `@functools.lru_cache` or
`@functools.cache` (Python 3.9+) before rewriting as iterative:
```python
from functools import cache

@cache
def fib(n: int) -> int:
    if n < 2:
        return n
    return fib(n - 1) + fib(n - 2)
```

### Batch over loop
Prefer single-operation batches to N individual calls:
```python
# WRONG — N round trips to DB
for user_id in user_ids:
    user = await db.get_user(user_id)

# CORRECT — 1 round trip
users = await db.get_users_batch(user_ids)  # IN clause
```

### Streaming over accumulation
For large result sets, yield rather than collect:
```python
# WRONG — loads all rows into memory
def get_all_events() -> list[Event]:
    return session.query(Event).all()  # 10M rows in memory

# CORRECT — streams row by row
async def stream_events() -> AsyncIterator[Event]:
    async for row in session.stream(select(Event)):
        yield Event.from_orm(row)
```

---

## When to Reach for Advanced Structures

| Problem | Structure | Import |
|---------|-----------|--------|
| Sorted list with fast inserts | `SortedList` | `sortedcontainers` |
| LRU / LFU cache | `LRUCache` / `LFUCache` | `cachetools` |
| Bloom filter | `BloomFilter` | `pybloom-live` |
| Trie (prefix matching) | `Trie` | `pygtrie` |
| Interval tree | `IntervalTree` | `intervaltree` |
| Graph operations | `Graph` | `networkx` |
| Sparse matrix | `csr_matrix` | `scipy.sparse` |

Always check if `stdlib` or `sortedcontainers` covers the need before adding a dependency.

---

## Complexity Quick Reference

| Operation | list | set | dict | deque | heapq |
|-----------|------|-----|------|-------|-------|
| Append | O(1)* | — | — | O(1) | O(log n) |
| Prepend | O(n) | — | — | O(1) | — |
| Lookup by index | O(1) | — | — | O(n) | — |
| Lookup by value | O(n) | O(1) | O(1) | O(n) | — |
| Insert (middle) | O(n) | O(1) | O(1) | O(n) | — |
| Delete (middle) | O(n) | O(1) | O(1) | O(n) | — |
| Min/max | O(n) | O(n) | O(n) | O(n) | O(1) |
| Sort | O(n log n) | — | — | — | — |

*amortized
