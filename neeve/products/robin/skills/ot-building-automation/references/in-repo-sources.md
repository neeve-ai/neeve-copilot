# In-repo sources of truth

These are Neeve's own, already-validated domain content — read them before
writing Niagara/BQL/WebCTRL code. If one of these paths has moved, update
this file rather than letting it go stale.

## `niagara-robin-agent`

- `.github/instructions/niagara-bql.instructions.md` — the canonical BQL
  reference for this codebase: ORD path conventions, extent types, predicate
  patterns, aggregate/scalar functions, history/rollup queries, alarm/audit
  queries, BFormat tokens, and the `javax.baja.bql` Java API patterns
  (`BqlQuery`, `BITable`, `Cursor`, `TableCursor`) with worked examples.
- `.github/instructions/niagara-module.instructions.md` — module directory
  layout, `niagara-module.xml`/`module-include.xml`/`module.lexicon`/
  `module.palette`/`module-permissions.xml`, `@NiagaraType`/`@NiagaraProperty`/
  `@NiagaraAction`/`@NiagaraEnum`/`@NiagaraRpc` annotation patterns and
  Slot-o-Matic generated-code regions, singleton/agent-type patterns, Gradle
  build structure, test class conventions (`BTestNg` vs `BStationTestBase`).
- `README.md` — architecture diagram (`BRobinServlet` → `ToolRegistry` → BQL
  service interfaces → station), the 12 MCP tools this repo exposes, and the
  "Niagara-Specific Constraints" section: threading (`BWorker`/
  `Flags.ASYNC`), Gson reflection restrictions, Jetty WebSocket usage, TLS
  trust-all for outbound `wss://`, daemon-thread requirement for
  `ExecutorService`.
- `docs/bql-service-implementation.md` — this repo's actual BQL service
  implementations and `BqlHelper` usage.
- `docs/robin-mcp-server-reference.md` — full MCP protocol/tool reference for
  the Robin MCP server running inside the station.
- `docs/robin-websocket-tunnel-client.md`, `docs/robin-cloud-config-websocket.md`
  — the outbound cloud tunnel implementation and its Niagara-specific
  constraints.

## `alc-robin-agent` / `alc-hello-addon`

- `README.md` — WebCTRL add-on API surface, config persistence lifecycle
  (atomic write via temp-file-then-replace to avoid corruption), and the
  `keytool`-based add-on signing procedure (cert copied into
  `WebCTRL8.0/programdata/addons`).
- `CLAUDE.md` — WebCTRL add-on structure (`info.xml`, `web.xml`, `.addon`
  packaging), `ServletContextListener` lifecycle, Java 11 / `jenv` toolchain
  requirement, threading guidance (never block the WebCTRL server thread).
- `alc-robin-agent/docs/feature-frontend.md`,
  `alc-robin-agent/docs/feature-user-config-api.md` — the add-on's own
  frontend and config-API feature docs.
