#!/usr/bin/env bash
# SessionStart hook: echoes this repo's spec-based-development status so a
# session opened cold doesn't skip straight to code. Informational only.
set -uo pipefail

context_file=""
for candidate in AGENTS.md .github/copilot-instructions.md CLAUDE.md; do
  if [[ -f "${candidate}" ]]; then
    context_file="${candidate}"
    break
  fi
done

if [[ -z "${context_file}" ]]; then
  exit 0
fi

if grep -q "Spec-Based Development" "${context_file}" 2>/dev/null; then
  echo "[neeve-hooks] This repo follows Spec-Based Development — read the spec before writing code (see ${context_file})."
else
  echo "[neeve-hooks] Context loaded from ${context_file}."
fi

exit 0
