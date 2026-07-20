---
name: ot-building-automation
description: Domain grounding for Tridium Niagara 4 / BQL and ALC WebCTRL building-automation work. Use when touching alc-hello-addon, alc-robin-agent, or niagara-robin-agent, or anything that talks to a Niagara station or WebCTRL server.
---

## Why this skill exists

Robin's building-automation surface (`niagara-robin-agent`, `alc-robin-agent`,
`alc-hello-addon`) is how Robin gives AI agents and facilities operators
structured access to real BMS points, alarms, schedules, overrides, and trend
history — a Niagara station or WebCTRL server sitting between this code and
actual HVAC, lighting, and access-control equipment in a customer's building.
Generic Java/Copilot suggestions default to web-app idioms that are wrong
here (see Gotchas below); this skill exists to stop that default.

**This content is sourced primarily from what's already validated in these
three repos** (their READMEs, `docs/`, and `.github/instructions/`) — treat
those as the ground truth and this skill as an index into them, not a
replacement. Where a claim is drawn from public vendor/community
documentation instead of an in-repo source, it's marked `[external]` and
should be treated as directional, not verified against a live station.

## Start here — in-repo sources of truth (read before writing code)

| Repo | File | Covers |
|---|---|---|
| `niagara-robin-agent` | `.github/instructions/niagara-bql.instructions.md` | Full BQL syntax reference: ORD schemes, extents, predicates, aggregates, history/rollup queries, alarm/audit queries, `javax.baja.bql` Java patterns |
| `niagara-robin-agent` | `.github/instructions/niagara-module.instructions.md` | Module layout, `@NiagaraType`/`@NiagaraProperty`/`@NiagaraAction` annotation patterns, Slot-o-Matic, `module-include.xml`, palette/lexicon files, RPC endpoints, permissions |
| `niagara-robin-agent` | `README.md` (Niagara-Specific Constraints) | Threading (never block the station engine thread — `BWorker`/`Flags.ASYNC`), Gson reflection blocked by Niagara's SecurityManager, Jetty WebSocket (not OkHttp), TLS trust-all for outbound `wss://`, `ExecutorService.shutdown()` needs `modifyThread` permission (use daemon threads) |
| `niagara-robin-agent` | `docs/bql-service-implementation.md`, `docs/robin-mcp-server-reference.md` | This repo's actual BQL service implementations and the 12 MCP tools built on top of them |
| `alc-robin-agent`, `alc-hello-addon` | `README.md` | WebCTRL add-on signing (`keytool` + `.cer` into `WebCTRL8.0/programdata/addons`), add-on API surface, config lifecycle (atomic `config.dat` write via temp-file-then-replace) |
| `alc-robin-agent`, `alc-hello-addon` | `CLAUDE.md` | WebCTRL add-on structure (`info.xml`, `web.xml`, `.addon` packaging), `ServletContextListener` lifecycle, `jenv`/Java 11 toolchain requirement |

If an answer isn't in these files, say so explicitly rather than guessing —
BQL syntax and Niagara/WebCTRL runtime behavior are easy to get subtly wrong
in ways that only surface against a live station.

## Component model in one paragraph

A Niagara **station** hosts a tree of **components** (`BComponent`
subclasses, always `B`-prefixed) under a `Nav` tree, each exposing typed
**slots** (properties/actions/topics) accessed through the `javax.baja.*`
Baja API — not plain Java getters. **Modules** are signed jars built against
a specific N4 version; a module built against the wrong version can fail to
install or load. **BQL** (`slot:...|bql:select ... from ... where ...`) is
Niagara's SQL-like query language over that component tree, histories, and
the alarm database — see `niagara-bql.instructions.md` for the full syntax,
not a summary here.

WebCTRL (`alc-*` repos) is Automated Logic's platform built on Niagara; its
add-ons are signed, `.addon`-packaged servlet modules with their own
lifecycle (`ServletContextListener`) layered on top of the station.

## Gotchas that don't show up in a normal code review

- **Threading**: blocking the station engine thread stalls the whole
  station, not just one request. Any I/O or long-running work must go
  through `BWorker`/`Clock.schedule`/`Flags.ASYNC` — flag synchronous I/O on
  a Niagara call path as a correctness bug, not a style nit.
- **Reflection is restricted**: Niagara's SecurityManager blocks
  `Field.setAccessible`, which breaks naive Gson POJO (de)serialization —
  `niagara-robin-agent` parses/builds JSON manually via `JsonObject`/
  `JsonArray` for this reason. Don't suggest a reflection-based JSON library
  default here.
- **Version skew**: a station upgrade can silently break a module that
  wasn't rebuilt against the new N4 SDK. Treat any Niagara/Gradle plugin
  version bump as needing a station-compatibility check, not just "it
  compiles."
- **Physical-world side effects**: invoking an action on a point (override,
  schedule change) can affect real equipment immediately. Weigh "what
  happens if this runs against a live station" more heavily than in a
  typical CRUD review — this is why `niagara-robin-agent`'s 12 MCP tools are
  all read/query tools (alarms, schedules, history, point values), not
  write/override actions.
- **Point status is not a normal error state** `[external]`: BACnet/Modbus
  field points report `stale`/`fault`/`overridden` status flags rather than
  throwing exceptions on transient unavailability — don't treat a stale
  point value as something a generic try/catch should swallow or retry
  aggressively.

## When to stop and ask

- Any BQL query shape not already covered in `niagara-bql.instructions.md`.
- Any change that would let an agent invoke a write/override action against
  a live station — that's a product/safety decision, not just a code change.
- Any module manifest, Niagara SDK version, or WebCTRL SDK version change —
  station/server compatibility can't be verified from source alone. Invoke
  `debug-trace` to ground the actual SDK version pinned in this repo (module
  manifest, build file) and research that version's real behavior/breaking
  changes before assuming training-data knowledge of "Niagara" or "WebCTRL"
  in general still applies — N4 and WebCTRL SDK behavior changes across
  versions the same way any other dependency's does. Include the **Depth
  check** line (`debug-trace`'s Disclosure Requirement) in the Production
  Consequence & Gaps section below.

## Production Consequence & Gaps — required for any change here

Unlike a typical backend service, "production" here means a live building —
state the consequence in those terms, not just request/response terms:

- **What physical/operational effect could this have** if wrong — a stalled
  station engine thread, a schedule or override reaching real equipment, a
  point read returning stale data treated as fresh.
- **Blast radius**: one point, one station, every station on this integration,
  or (if a module/SDK version change) every deployment running that module.
- **Rollback story**: can this be reverted without a station restart /
  re-provisioning cycle, or does undoing it require physical/on-site access?
- **Gaps**: anything that "can't be verified from source alone" (see "When to
  stop and ask" above) is a gap, not a non-issue — name it rather than
  letting it pass silently because the code compiles.

## References

- `references/in-repo-sources.md` — direct links to the files in the table
  above, kept in sync if those repos restructure their docs.
- `references/external-docs.md` — supplementary vendor/community links
  (Tridium sample code, BQL community write-ups, WebCTRL integration
  overview) for background reading; not a substitute for the in-repo sources.
