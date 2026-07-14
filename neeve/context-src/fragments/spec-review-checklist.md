## Spec-Based Development — Routing

This project follows **Spec-Based Development**{{SPEC_WIKI_REF}}.
Specs live on `spec/<TICKET-ID>` branches; implementations live on `feat/<TICKET-ID>` branches.
The two are reviewed separately and never blended.

| Source branch | PR purpose | Checklist to use |
|---------------|-----------|-----------------|
| `spec/<TICKET-ID>` | Stage 2 — spec authoring and review | **SPEC FILE REVIEW** — run all 8 checks; do not review code |
| `feat/<TICKET-ID>` | Stage 3 — implementation against frozen spec | **CODE REVIEW** — verify implementation matches the approved spec |
| `fix/*`, `chore/*` | Bug fix or maintenance | **CODE REVIEW** |
| PR touches both `specs/*.md` and source files | Spec amendment during implementation | Run **SPEC FILE REVIEW** on the spec delta first; flag any amendment that changes more than 30% of ACs as requiring a new spec PR |

Do not blend the checklists. A spec review judges the document against intent; a code review judges the implementation against the frozen spec.

---

## SPEC FILE REVIEW

When asked to review a file in `specs/`, run the following checks. Each check maps to a finding tier: 🔴 Critical (spec must be fixed before implementation starts) | 🟡 Major (fix before PR) | 🟢 Minor (fix in follow-up).

### 1. Scope Accuracy — Does the spec cover exactly what was asked?

Source of truth for scope: {{ADR_SOURCE_OF_TRUTH}}.

- Read the work item definition. Map every acceptance criterion in the source of truth to a Functional Requirement (FR) in the spec.
- 🔴 **Scope gap**: A work item acceptance criterion has no corresponding FR or AC in the spec.
- 🟡 **AC under-specified**: A FR exists but the AC does not say how it will be verified (what mock/assert/DB state proves it).
- 🟢 **Wording drift**: The spec AC uses different terminology than the source of truth without noting the divergence.

### 2. Scope Bleed — Does the spec implement things not asked for?

- Read every FR, NFR, DoD item, and metric definition. Check whether the source of truth mentions it.
- 🔴 **Hard scope bleed**: A FR implements behavior that belongs to a different, named work item.
- 🟡 **Soft scope bleed**: An NFR bullet, metric, DoD item, or performance baseline was added with no basis in the source of truth.
- 🟢 **Additive annotation**: An informational note or definition row that could belong in a follow-up.

For each bleed finding, state: *what was added*, *which spec section*, *why it is out of scope*, and *whether it should be moved to a named future work item or simply deleted*.

### 3. Reuse First — Does the spec leverage what already exists?

Read the relevant implementation files in {{SOURCE_ROOT}} before reviewing the spec's file impact and FR descriptions.

Check:
- **Error handling patterns**: Does the spec define a new error-handling approach when the codebase already has one?
- **Session/client/connection patterns**: Does the spec open resources the same way existing code does? Flag if it describes a one-instance approach when the codebase uses many, or vice versa.
- **Test fixture patterns**: Does the spec describe tests the same way the nearest existing test file does? Check this repo's actual test conventions (mocked boundaries vs. real infra) before flagging a mismatch.
- **Model / DTO field names**: Are field names verified against the actual model/schema files, not assumed?
- **Migration / schema revision references**: Are revision IDs or schema versions quoted correctly against the files that actually exist?

🟡 for each pattern mismatch. 🔴 if a new library or global singleton is introduced that the codebase doesn't use.

### 4. Integration Test as Acceptance Criteria — Is every AC backed by a named test?

- Every AC in the spec must map to either a unit test (in `Required Tests → Unit`) or a named integration test (`IT-N` in `Required Tests → Integration`).
- 🔴 **Unmapped AC**: An acceptance criterion exists with no corresponding test name or IT-N reference.
- 🔴 **Integration test covers wrong path**: An IT-N's setup/mocks don't match the FR logic it claims to cover.
- 🟡 **Missing negative AC**: The spec has no AC for the failure path of a critical FR (race condition, constraint violation, dependency unreachable).
- 🟡 **AC claims infra it doesn't use**: ACs and DoD items must accurately describe whether tests hit real infra or mocked boundaries — verify against this repo's actual test setup.
- 🟢 **IT ordering**: Integration test numbers should be sequential in the file (IT-1 before IT-2, etc.).

For each gap, name the AC and the missing IT-N or unit test case title.

### 5. AC Robustness and Thoroughness

For each FR, ask: what can go wrong?

Required coverage checklist:
- [ ] Happy path
- [ ] Concurrent access (same-actor race, multi-replica race)
- [ ] Infrastructure failure (dependency unavailable, connection error)
- [ ] Missing/null inputs
- [ ] Idempotency (repeat request/operation is safely a no-op or correctly rejected)
- [ ] Incorrect data (invalid enum/mapping value, mismatched constraint)
- [ ] Pre-existing state (resource already created/provisioned by another path)
- [ ] Re-raise vs. swallow (exception classification: transient → catch and continue; data bug → re-raise)

🔴 if a concurrency or idempotency path is in the FR text but has no AC.
🟡 if a negative path exists in Edge Cases but has no AC or test case.
🟢 if an AC exists but the verification method is vague ("no exception raised" without specifying what was called or not called).

### 6. Technical Accuracy — Is the spec grounded in the actual codebase?

Read the files named in "File / Module Impact" before reviewing.

Check:
- **File paths exist**: Every file listed in File Impact either exists today or is explicitly marked `NEW`. Flag if a `MODIFY` target doesn't exist.
- **Field/attribute names match the real schema/ORM/type definitions.**
- **Language/runtime behavior claims are correct** — verify any stated behavior of the language or framework rather than assuming it.
- **Exception/error types named in the spec actually exist** in the language/framework/library referenced.
- **Data-access counts** (e.g. "N calls on the happy path") match the actual FR logic — count each call through the sequence rather than trusting the stated number.
- **Key/identifier formats** in Data Model match what the FR code actually writes.

🔴 for wrong field name, wrong exception/error type, or wrong runtime-behavior claim — these become bugs on day one.
🟡 for wrong count or TTL/timeout value in an NFR bullet.
🟢 for identifier/revision formatting.

### 7. Cross-Repo and Cross-Spec Citations — Are references accurate?

- **ADR citations**: When the spec cites an ADR section, verify the referenced section heading exists in the ADR file.
- **Work item references**: When the spec says another work item "writes …" or "owns …", verify the claim against the work item tracker.
- **Cross-spec references**: When the spec references another spec, verify the referenced section heading exists in that spec file.
- **Contract/ownership tables**: When a spec defines which work items own which shared contract, verify the table is consistent with both the referenced spec and the source of truth.

🟡 for a cited ADR section that doesn't exist.
🟡 for a cross-spec reference where the section heading has drifted.
🟢 for a work item assignment that is plausible but unverified.

---

### 8. Spec Template Compliance — Does the spec follow the Neeve spec format?

Reference: {{SPEC_WIKI_REF_SHORT}} → Spec Template and Spec Review Checklist sections.

**AC format — Given/When/Then:**
- Every AC must be in the form `Given … When … Then …` (binary pass/fail).
- 🔴 ACs written as prose assertions with no Given/When/Then.
- 🟡 ACs that are not binary — "the system handles X gracefully" has no testable outcome.

**AC traceability annotations:**
- Every test that covers an AC must carry `# spec: AC-xx` in the test file.
- 🟡 If Required Tests section lists test functions but none carry `# spec:` annotation instructions, flag it.

**AC ID discipline:**
- IDs must be sequential (`AC-01`, `AC-02`, …). Retired IDs must be struck through (`~~AC-05~~ (removed: reason)`) not silently deleted.
- 🟡 Gaps in AC numbering without a retirement note.

**Named constraints:**
- Every database/schema constraint introduced in Data Model must have an explicit name, and the migration file must use the same name.
- 🔴 A constraint without an explicit name.

**Bounded context:**
- The spec must identify which domain owns the feature, either in Metadata or in a Definitions entry.
- 🟡 No bounded context identified.

**Domain type aliases:**
- Where the spec passes a raw primitive for a typed identifier, it should name a typed alias. Check the Enums / Type Aliases section.
- 🟢 Missing type aliases where primitives are used.

**OKF book alignment:**
- Every new domain term in the Definitions table should also appear in the repo's OKF book (`.help/index.md`/`.help/introduction.md`, when it exists). Flag if the spec introduces terms that don't appear there.
- 🟢 New terms not yet in the OKF book (non-blocking if this repo hasn't run `init-repo.sh`/`repo-intel` yet).

**Definition of Done completeness:**
- DoD must include: ≥95% line + branch coverage, zero strict-type-checker errors, every AC has ≥1 annotated test (`# spec: AC-xx`), named constraints used, observability metrics specified.
- 🟡 Any of these absent from the DoD checklist.

---

### Spec Review Output Format

```
## Spec Review: [filename]

### 🔴 Critical (must fix before implementation)
1. [Check category] — [specific finding]
   - Evidence: [line/section in spec]
   - Ground truth: [file/section that contradicts it]
   - Fix: [exact change]

### 🟡 Major (fix before PR)
...

### 🟢 Minor (fix in follow-up)
...

### ✅ What's correct
- [Verified items worth noting]

### Review coverage
- Spec file read: [yes/no]
- Source of truth read: [file and sections]
- Codebase files verified: [list]
- Cross-spec files verified: [list]
```
