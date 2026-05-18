# Type Safety & Linting Reference (mypy / ruff)

## mypy Enforcement

Run mentally as if `mypy --strict` is active. Flag every violation.

### Missing annotations (HIGH)

```python
# BAD
def process(data, config=None):
    return data["value"] * config.multiplier

# CORRECT
def process(data: dict[str, int], config: ProcessConfig | None = None) -> int:
    if config is None:
        config = ProcessConfig.default()
    return data["value"] * config.multiplier
```

### Unjustified `Any` (HIGH)

```python
# BAD — lose all type safety downstream
def parse(raw: Any) -> Any:
    return json.loads(raw)

# CORRECT — narrow the type
def parse(raw: str | bytes) -> dict[str, object]:
    return json.loads(raw)
```

### `# type: ignore` without justification (MEDIUM)

```python
# BAD
result = some_lib.call()  # type: ignore

# CORRECT
result = some_lib.call()  # type: ignore[attr-defined]  # third-party lib missing stubs
```

### Modern union syntax (Python 3.10+) (LOW)

```python
# BAD — legacy
from typing import Optional, Union, Dict, List, Tuple
def f(x: Optional[str]) -> Union[int, str]: ...

# CORRECT
def f(x: str | None) -> int | str: ...
# Use built-in dict, list, tuple — no import needed
def g(data: dict[str, list[int]]) -> tuple[int, ...]: ...
```

### Protocol over ABC for structural typing (MEDIUM)

```python
# Use Protocol when you want duck typing, ABC when you want inheritance
from typing import Protocol

class Serializable(Protocol):
    def to_json(self) -> str: ...

# Any class with to_json() satisfies this — no explicit inheritance needed
```

---

## ruff Rule Sets

### Always enforce

| Rule set | Key violations to flag |
|----------|----------------------|
| `E/W` | PEP 8 style — indentation, line length, whitespace |
| `F` | Pyflakes — unused imports, undefined names, unused variables |
| `I` | isort — import ordering |
| `B` | flake8-bugbear — common bugs |
| `C90` | McCabe complexity — flag CC > 10 |
| `UP` | pyupgrade — use modern Python syntax |
| `SIM` | flake8-simplify — unnecessary complexity |
| `RUF` | Ruff-specific — performance, correctness |

### High-value B (bugbear) rules

```python
# B006 — mutable default (see smells.md)
# B007 — loop variable not used in loop body
for i in range(10):   # B007 if 'i' never used — use '_'
    do_something()

# B008 — function call in default argument
def get(db: Session = get_db()):  # called once at definition time!
    ...

# B009/B010 — getattr/setattr with string literals (use direct access)
getattr(obj, "name")   # just use obj.name

# B017 — assertRaises without context manager
self.assertRaises(ValueError, func)   # doesn't catch — use:
with self.assertRaises(ValueError):
    func()

# B904 — raise in except without `from`
try:
    do()
except SomeError:
    raise OtherError("msg")   # loses traceback

# CORRECT
raise OtherError("msg") from e
```

### High-value SIM rules

```python
# SIM102 — nested if → and
if condition_a:
    if condition_b:   # merge to: if condition_a and condition_b:
        ...

# SIM108 — ternary instead of if/else assignment
if x > 0:
    result = "positive"
else:
    result = "other"
# → result = "positive" if x > 0 else "other"

# SIM117 — merge context managers
with open(a) as f:
    with open(b) as g:   # → with open(a) as f, open(b) as g:
        ...
```

### Cyclomatic Complexity

- CC ≤ 10: acceptable
- CC 11–15: MEDIUM — add comment explaining branches, consider extraction
- CC > 15: HIGH — must refactor; split function

```python
# Detecting high complexity mentally:
# Count: function entry (1) + each if/elif/for/while/except/and/or (+1 each)
# A function with 3 nested ifs and a for loop = CC of ~7
```

---

## TypeScript (if reviewing TS)

- `any` usage → same rules as Python `Any`
- Missing return types on exported functions
- Non-null assertions (`!`) without comment
- `as SomeType` casts without validation (use type guards or Zod)
- `interface` vs `type` — prefer `interface` for object shapes, `type` for unions/intersections
- Missing `readonly` on props that shouldn't be mutated
