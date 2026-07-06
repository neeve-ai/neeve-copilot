## Product Overview: Robin

Robin is Neeve's AI co-pilot for building operations — it works inside the
browser, alongside existing OT web apps (Tridium Niagara, energy dashboards,
maintenance tools), reading on-screen data to answer questions, summarize
insights, and troubleshoot alarms/configuration issues. It deliberately does
not submit forms or perform control actions today — advisory/supervisory only,
by design, because its actions sit upstream of real building equipment.

### Repos in this product

{{PRODUCT_REPO_TABLE}}

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
