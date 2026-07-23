# The PRD as System of Record (SoR)

Canonical contract for treating a feature's PRD as its living, version-controlled
master record. Cited by `to-prd`, `to-erd`, `to-spec`, `neeve-dls` (PRD Prototype
Mode), and enforced by the `neeve` agent's Acceptance Contracts. Edit this file;
do not restate its rules inline in a skill.

## The rule in one line

Once a feature has a PRD, that PRD is the **single source of truth** for the
feature's intent, scope, and requirements — through Design, ERD, Spec,
Implementation, and Review. It is one evolving git-versioned document, never
forked per phase, and no downstream doc (ERD, spec, code) may silently
contradict it. When a later phase changes what the PRD says, the change goes
**back into the PRD, with the reason, in the same commit** — not only into the
downstream artifact.

## Where it lives

`<product-planning-repo>/prds/<feature-slug>.md` — the product's planning repo
(`robin-adr/prds/` for Robin today; the same convention for any other product's
planning repo). One file per feature, keyed by the stable `feature-slug`
`to-prd` mints and every downstream stage reuses verbatim.

## Two audit layers — git + the in-doc log

- **Git is the version-control / collaborator / audit substrate.** Every change
  is a commit; `git log`/`git blame` answer *who* changed *what*, *when*.
  Multiple people editing the same PRD over time is normal and expected — git
  handles concurrent authorship. Never keep a private copy; edit the one file.
- **The in-doc Decision Log answers *why*.** Git records the diff; the log
  records the reasoning a diff can't. Both are required — a commit with no log
  entry loses the "why"; a log entry with no commit isn't audited.

## Lifecycle Status (top of the PRD)

A single `**Status:**` line that advances as the feature moves through the
Design Loop — the at-a-glance "which phase is this in":

```
draft → reviewed → approved → in-design → in-erd → in-spec → in-implementation → shipped
```

Plus `superseded` / `archived` for a PRD that a later PRD replaces or that is
abandoned. Advancing the status is itself a Decision Log entry.

## The Change & Decision Log (in every PRD)

An **append-only** table near the top of the PRD — new rows added, prior rows
never edited or deleted (corrections are new rows). Format:

```markdown
## Change & Decision Log

| Date | Phase | Author | Change | Why | Commit/PR |
|------|-------|--------|--------|-----|-----------|
| 2026-07-23 | PRD | @author | Initial PRD | New feature request from <persona> | abc1234 |
```

- **Phase** = which Design-Loop stage the change was made in (PRD / Design /
  ERD / Spec / Implementation / Review).
- **Why** = the decision rationale, not a restatement of the Change. "Removed
  bulk-export from scope" is the change; "export volume can't be tenant-scoped
  safely yet — deferred, tracked as open question Q4" is the why.
- **Commit/PR** = the **git short SHA** of the commit that made the change
  (e.g. `abc1234`), so anyone — human or agent — can jump straight to the full
  diff and context behind the decision: `git show abc1234` /
  `git log -1 abc1234`. A PR link may accompany the SHA but does not replace
  it; the SHA is what makes the row directly jumpable in the checkout.

### Populating the commit SHA (the ordering reality)

A row cannot contain the hash of the commit it is *part of* — the hash isn't
known until after the commit exists. Use this order:

1. Edit the PRD section + append the Decision Log row with the Commit cell as
   a placeholder (`pending`).
2. Commit the change (PRD edit + row together): `git commit -m "prd(<slug>):
   <phase> — <what>"`.
3. Read the resulting hash — `git rev-parse --short HEAD` — write it into the
   row's Commit cell, and either `git commit --amend --no-edit` (if not yet
   pushed) or make one tiny follow-up commit `prd(<slug>): record decision-log
   SHA`. The amended/final hash is stable from then on.

For a PR/squash-merge flow, record the PR link at step 1 and backfill the
squash-merge short SHA once it exists — the PR is knowable before merge, the
SHA after.

## Write-back rule (the gate every later phase obeys)

Any phase after PRD creation that changes the PRD's **scope, a requirement, an
assumption, a success metric, or a decision** must, in the *same commit*:

1. Edit the affected PRD section so the PRD stays correct.
2. Append one Decision Log row with the reason and the phase (Commit cell
   `pending` for now).
3. Advance `Status:` if the phase changed.
4. Commit atomically, message `prd(<feature-slug>): <phase> — <what changed>`.
5. Record the resulting short SHA into the row's Commit cell (see "Populating
   the commit SHA" above) so the decision is directly jumpable.

If a phase discovers the PRD is *already* stale (a downstream doc or the code
diverged from it without a log entry), reconcile the PRD first — that
reconciliation is itself a logged decision — before continuing.

## Decision-state check at each phase transition

Before a stage starts work, verify the PRD is current: Status reflects reality,
open questions are resolved or explicitly deferred (with a reason, not dropped),
and no downstream artifact silently contradicts it. A stale PRD is reconciled
before the stage proceeds, never worked around.

## Relationship to ADRs — complementary, not duplicated

An *architecture* decision still gets an ADR via `rca-retro-adr`
(`docs/adr/ADR-NNNN-<slug>.md`). The PRD Decision Log records the *product /
scope* decision and links to the ADR by number; the ADR records the technical
rationale. Two homes, cross-linked, never the same content copied twice.
