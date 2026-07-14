## Product Overview: Robin

Robin is Neeve's AI co-pilot for building operations — it works inside the
browser, alongside existing OT web apps (Tridium Niagara, energy dashboards,
maintenance tools), reading on-screen data to answer questions, summarize
insights, and troubleshoot alarms/configuration issues. It deliberately does
not submit forms or perform control actions today — advisory/supervisory only,
by design, because its actions sit upstream of real building equipment.

### Repos in this product

| Repo | Contribution to Robin |
|---|---|
| `alc-hello-addon` | Example/scaffold WebCTRL add-on — reference implementation for building-automation integrations, not a production Robin surface. |
| `alc-robin-agent` | WebCTRL agent — exposes ALC WebCTRL building-automation data/actions to Robin. |
| `dls-neeve` | Shared design system (@neeve/dls) and fonts package — the single source of pixel-perfect components/tokens consumed by robin-web and robin. |
| `mcp-nats-handler` | NATS-to-MCP bridge — exposes internal NATS-based services as MCP tools other Robin components can call. |
| `neeve-web` | Placeholder repo — not yet built out; stack/role to be filled in once work starts here. |
| `niagara-robin-agent` | Niagara N4/BQL agent — exposes Tridium Niagara station data (alarms, points, schedules, history) to Robin via read-only MCP tools. |
| `robin-adr` | Product-wide planning repo — ADRs, work-item breakdowns, and (new) PRDs/ERDs live here; the source of truth for what's being built and why, one level above any single repo. |
| `robin-ai` | Main backend — the policy/API authority for Robin; owns the primary database schema and orchestrates the other services. |
| `robin-commons` | Shared Python library (resilience, observability, messaging helpers) used across robin-ai and the other backend services to avoid duplicated infrastructure code. |
| `robin-expirements` | Scratch space for AI/eval research experiments — not a shipped product surface. |
| `robin-helm` | Helm charts that deploy the full Robin stack (robin-ai, robin-web, gateway, observability) to Kubernetes, including each developer's own sandbox namespace. |
| `robin-kb-service` | Knowledge-base / long-term-memory service backing Robin's AI features. |
| `robin-testbench` | Automated browser-based test harness that exercises Robin's Chrome extension flows end-to-end. |
| `robin-web` | Admin portal — the enterprise/org-management frontend (React) and its BFF backend (FastAPI), used by facilities/security-ops admins, not end users of the extension. |
| `robin` | The Robin Chrome extension itself — the AI co-pilot surface an end user (facilities/security-ops staff) actually installs and uses inside their existing OT web apps. |
| `wstunnel-reverse-proxy` | WebSocket tunnel reverse proxy — exposes MCP servers sitting behind NAT (e.g. an OT-side Niagara connection) back to robin-ai. |

### How to run Robin locally

Two paths, not mutually exclusive:

1. **Per-repo local dev** — each repo above documents its own start command
   in its own "Running Locally" section (this file), e.g. `robin-ai`'s
   `make dev-up` + `make run`, or `robin-web`'s connected-mode
   `docker-compose.robin-ai.yml`. Fastest for iterating on one repo at a time.
2. **Your own namespace (`sbox-$(DEVELOPER)`)** — `robin-helm` can deploy the
   whole stack (robin-ai + robin-web + gateway + observability) into a
   personal Kubernetes namespace on the shared dev cluster:
   ```bash
   export DEVELOPER={your-name}
   cd robin-helm && make dev DEVELOPER=$DEVELOPER
   ```
   Reachable at `https://$DEVELOPER.dev.robin.neeve.ai` once pods are ready
   (`kubectl get pods -n sbox-$DEVELOPER -w`). This is real, working
   infrastructure today — not a future plan — but it's fully manual: no CI
   creates or tears down a namespace per branch/PR, and it deploys to shared
   cluster infrastructure, not your laptop. Requires AWS SSO access and a
   couple of one-time `kubectl`/AWS CLI setup steps — see `robin-helm/README.md`
   in full for secrets setup, rollback (`helm rollback robin-$DEVELOPER -n
   sbox-$DEVELOPER`), and teardown (`make clean`).
