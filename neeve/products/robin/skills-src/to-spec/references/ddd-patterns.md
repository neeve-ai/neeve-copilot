# DDD Patterns Reference

## Layer Architecture

```
┌─────────────────────────────────────────────────────┐
│  Presentation Layer (routes, WebSocket handlers,    │
│  CLI entry points, background worker entry points)  │
├─────────────────────────────────────────────────────┤
│  Application Layer (use cases, commands, queries,   │
│  event handlers, orchestrators)                     │
├─────────────────────────────────────────────────────┤
│  Domain Layer (entities, value objects, aggregates, │
│  domain events, domain services, repository         │
│  protocols)                                         │
├─────────────────────────────────────────────────────┤
│  Infrastructure Layer (repository implementations,  │
│  ORM models, message bus clients, cache adapters,   │
│  external API clients)                              │
└─────────────────────────────────────────────────────┘
```

**Dependency rule:** inner layers never import from outer layers.
`domain` → nothing. `application` → `domain`. `infrastructure` → `domain` + `application`.
`presentation` → `application`.

---

## Domain Objects

### Entity

Has identity, mutable state, lifecycle.

```python
from dataclasses import dataclass, field
from uuid import UUID, uuid4

@dataclass
class User:
    id: UUID = field(default_factory=uuid4)
    email: str = ""
    role: str = "viewer"

    def promote_to(self, new_role: str) -> "RoleChanged":
        """Domain logic lives here. Raises domain events."""
        if new_role == self.role:
            raise ValueError(f"User already has role {new_role}")
        old_role = self.role
        self.role = new_role
        return RoleChanged(user_id=self.id, old_role=old_role, new_role=new_role)
```

### Value Object

No identity, immutable, equality by value.

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class OrgId:
    value: str

    def __post_init__(self) -> None:
        if not self.value.startswith("org_"):
            raise ValueError(f"Invalid org ID format: {self.value}")
```

### Aggregate

Enforces invariants over a cluster of entities.

```python
@dataclass
class RoleAssignment:
    """Aggregate root for role state within an org."""
    org_id: OrgId
    user_id: UUID
    current_role: str
    _events: list[DomainEvent] = field(default_factory=list, repr=False)

    def assign_role(self, role: str) -> None:
        self._validate_role(role)
        self._events.append(RoleAssigned(self.org_id, self.user_id, role))
        self.current_role = role

    def collect_events(self) -> list[DomainEvent]:
        events, self._events = self._events, []
        return events

    def _validate_role(self, role: str) -> None:
        valid = {"viewer", "operator", "admin", "super_admin"}
        if role not in valid:
            raise ValueError(f"Unknown role: {role}")
```

---

## Repository Protocol

The domain defines what it needs. Infrastructure implements it.

```python
# domain/repositories.py
from typing import Protocol
from uuid import UUID
from .entities import RoleAssignment
from .value_objects import OrgId

class RoleAssignmentRepository(Protocol):
    async def get(self, org_id: OrgId, user_id: UUID) -> RoleAssignment | None: ...
    async def save(self, assignment: RoleAssignment) -> None: ...
    async def delete(self, org_id: OrgId, user_id: UUID) -> None: ...
```

```python
# infrastructure/repositories/postgres_role_assignment_repo.py
from sqlalchemy.ext.asyncio import AsyncSession
from domain.repositories import RoleAssignmentRepository  # only domain import
from domain.entities import RoleAssignment
from domain.value_objects import OrgId

class PostgresRoleAssignmentRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get(self, org_id: OrgId, user_id: UUID) -> RoleAssignment | None:
        row = await self._session.execute(
            select(UserRoleORM).where(
                UserRoleORM.org_id == org_id.value,
                UserRoleORM.user_id == user_id,
            )
        )
        orm = row.scalar_one_or_none()
        return RoleAssignment.from_orm(orm) if orm else None
```

---

## Application Service (Use Case)

```python
# application/use_cases/assign_role.py
from domain.repositories import RoleAssignmentRepository
from domain.value_objects import OrgId
from infrastructure.event_bus import EventBus

class AssignRoleUseCase:
    def __init__(
        self,
        repo: RoleAssignmentRepository,   # protocol, not concrete class
        event_bus: EventBus,
    ) -> None:
        self._repo = repo
        self._event_bus = event_bus

    async def execute(self, org_id: OrgId, user_id: UUID, new_role: str) -> None:
        assignment = await self._repo.get(org_id, user_id)
        if assignment is None:
            assignment = RoleAssignment(org_id=org_id, user_id=user_id, current_role="")
        assignment.assign_role(new_role)
        await self._repo.save(assignment)
        for event in assignment.collect_events():
            await self._event_bus.publish(event)
```

---

## Domain Events

```python
from dataclasses import dataclass
from datetime import datetime, UTC
from uuid import UUID
from .value_objects import OrgId

@dataclass(frozen=True)
class DomainEvent:
    occurred_at: datetime = field(default_factory=lambda: datetime.now(UTC))

@dataclass(frozen=True)
class RoleAssigned(DomainEvent):
    org_id: OrgId
    user_id: UUID
    role: str
    old_role: str | None = None
```

---

## GOD Object Prevention

When writing specs, split large classes into focused domain objects.

**Signal:** A class does data access AND business logic AND event publishing.
**Fix:** Repository (data access) + Domain Entity (business logic) + Event Bus (publishing).

**Signal:** A class is called "Manager", "Handler", or "Service" and has >10 methods.
**Fix:** Identify the distinct responsibilities and split into one class per responsibility.

**Signal:** Methods in a class don't share state (they all operate on different fields).
**Fix:** Those methods belong in different classes.

---

## Naming Conventions

| Concept | Naming pattern | Example |
|---------|---------------|---------|
| Entity | Noun | `User`, `Order`, `RoleAssignment` |
| Value Object | Noun, often qualifed | `OrgId`, `EmailAddress`, `Money` |
| Repository protocol | `[Entity]Repository` | `UserRepository` |
| Repository impl | `[DB][Entity]Repository` | `PostgresUserRepository` |
| Use case | `[Verb][Noun]UseCase` | `AssignRoleUseCase` |
| Domain event | Past tense noun | `RoleAssigned`, `OrderPlaced` |
| Domain service | `[Noun]Service` (stateless) | `PermissionEvaluationService` |
| Application service | `[Noun]Service` (orchestrator) | `RBACApplicationService` |
