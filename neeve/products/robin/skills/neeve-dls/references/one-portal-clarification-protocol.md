# Clarification Protocol

The goal is to ask exactly the questions that prevent drift, and no more — over-asking
is its own failure mode (design team already feels unheard by the design-compliance
process; a skill that interrogates them for every button is not an improvement).

## Always ask when:

- A required prop (per the component's props table) has no value given or reasonably
  inferable from the conversation (e.g. a Table's `columns`/`data` shape).
- The component has multiple variants that meaningfully change appearance or behavior
  (Button: primary/secondary/ghost/destructive; AlertBanner: info/success/warning/
  danger) and the request doesn't specify or strongly imply one.
- The request exceeds a documented capability of the resolved component (see SKILL.md
  Step 2 — this is a different kind of question: it's not "which value" but "should I
  extend the component first").
- Two components could plausibly resolve the same plain-language ask (e.g. "table" →
  DLS `Table` vs `TableV2`) and context doesn't disambiguate.

## Don't ask when:

- The component file documents a sensible default and the request doesn't contradict
  it (e.g. Button defaults to `primary` size `md` unless stated otherwise — use the
  default, note the assumption inline in a comment or your response, move on).
- The missing detail is cosmetic and low-stakes (e.g. exact button label wording) —
  use a reasonable placeholder and flag it rather than blocking on it.
- The answer is already stated earlier in the conversation, even loosely ("this is for
  the admin-only danger zone" already implies `destructive` variant for a delete button
  — don't re-ask what's already answered).

## How to ask

Batch all outstanding questions for the current component (or set of components) into
one turn instead of a back-and-forth per prop. State briefly what's already decided so
the user isn't re-explaining context:

> "For the user table: I'll use `TableV2` since it needs sorting. Two things I need
> before building it: (1) which columns and are any of them resizable/hideable by
> default, (2) should row selection support bulk actions, or is this read-only?"

Never silently fabricate the missing piece and proceed — that's exactly the pattern
that produces prototypes that "look nothing like" the real component.
