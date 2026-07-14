## OT / Building-Automation Domain

This repo integrates with operational-technology building-automation systems
(Tridium Niagara 4 / BQL / WebCTRL) — a Niagara station or WebCTRL server
sits between this code and real HVAC/lighting/access-control equipment.
Before making changes here, read the `ot-building-automation` skill
(`/ot-building-automation` or `$ot-building-automation`): it indexes this
domain's actual sources of truth (`niagara-bql.instructions.md`,
`niagara-module.instructions.md`, and the `README`/`docs/` of
`niagara-robin-agent`, `alc-robin-agent`, and `alc-hello-addon`) rather than
restating them — generic Java/Copilot suggestions default to web-app idioms
that are wrong here (blocking the station thread, reflection-based JSON,
treating a stale point as a normal error). When a question isn't answered by
those in-repo sources, prefer asking a human over guessing — a wrong
assumption here can affect physical equipment.
