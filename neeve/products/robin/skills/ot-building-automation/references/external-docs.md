# External references (supplementary, not authoritative)

Background reading for context the in-repo sources don't cover. These are
vendor or community sources found via web search (mid-2026) — verify
against an actual station/server or a Neeve engineer before relying on
specifics, since none of these are Neeve-authored or Neeve-verified.

## Niagara 4 / BQL

- Tridium official sample code — [github.com/tridium/code-samples](https://github.com/tridium/code-samples)
  — example classes/modules for the Niagara Framework, maintained by Tridium.
- Tridium official — "Niagara Development with Tags, Relations and Queries"
  (NEQL/BQL combination) — [pages1.tridium.com/.../EntitiesTagsNEQL.pdf](https://pages1.tridium.com/rs/808-SGM-271/images/EntitiesTagsNEQL.pdf)
- "BQL in Niagara N4/AX" — BAS Briefing — [basbriefing.hashnode.dev/bql-in-niagara-n4-ax](https://basbriefing.hashnode.dev/bql-in-niagara-n4-ax)
  (community write-up; cross-check against `niagara-bql.instructions.md` before trusting a syntax detail).
- Community BQL query collections (illustrative only, not vendor-verified):
  [gist.github.com/mrupperman/8a0761bbb416b8ef1ca4f51c228f63bf](https://gist.github.com/mrupperman/8a0761bbb416b8ef1ca4f51c228f63bf),
  [github.com/thomasjupe/NiagaraN4BQLQueries](https://github.com/thomasjupe/NiagaraN4BQLQueries)
- An independent MCP-for-Niagara project (different implementation than
  Robin's, useful as a design comparison only):
  [github.com/mefodiytr/niagaramcp](https://github.com/mefodiytr/niagaramcp)

## WebCTRL

- Automated Logic official — WebCTRL integration overview —
  [automatedlogic.com/.../webctrl-building-automation-system/integration](https://www.automatedlogic.com/en/products/webctrl-building-automation-system/integration/)
- Automated Logic official — "WebCTRL: The Open Integration Platform" (PDF) —
  [automatedlogic.com/.../WebCTRL Open Integrations Platform...pdf](https://www.automatedlogic.com/en/media/WebCTRL%20Open%20Integrations%20Platform_110325_tcm702-284058.pdf)
- Niagara Marketplace — Automated Logic WebCTRL Driver for Niagara (shows
  the WebCTRL <-> Niagara point-import relationship from the other
  direction) — [niagaramarketplace.com/automated-logic-webctrl-driver.html](https://www.niagaramarketplace.com/automated-logic-webctrl-driver.html)

The WebCTRL Add-on SDK itself is licensed per Automated Logic partner
agreements and isn't fully public — for anything not already covered by
`alc-robin-agent`/`alc-hello-addon`'s own docs, the SDK license holder /
Automated Logic partner contact is the actual source of truth, not a public
search result.
