#!/usr/bin/env bash
# =============================================================================
# shared_refs_sync.sh — one canonical source for shared reference docs,
# generated copies inside each skill.
#
# Skill zips must stay self-contained (a skill installs as one directory,
# offline, per tool), so skills each carry a physical copy of shared docs
# like quality-gates.md. Before this script, those were six hand-maintained
# byte-identical files — one edit away from silent divergence. Now:
#
#   canonical:  neeve/references/quality-gates.md   (edit THIS one)
#   generated:  each destination below, stamped with a GENERATED header
#
#   sync    copy canonical -> every destination (skills_sync.sh pack calls
#           this first, so zips always embed the current canonical)
#   check   fail if any destination differs from canonical (CI gate)
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # neeve/

# canonical_relpath -> space-separated destination relpaths (relative to neeve/)
CANONICAL="references/quality-gates.md"
DESTINATIONS=(
  "skills-src/code-review/references/quality-gates.md"
  "skills-src/implement-spec/references/quality-gates.md"
  "skills-src/repo-ask/references/quality-gates.md"
  "skills-src/repo-intel/references/quality-gates.md"
  "skills-src/to-spec/references/quality-gates.md"
  "products/robin/skills-src/neeve-dls/references/quality-gates.md"
)

HEADER="<!-- GENERATED from neeve/${CANONICAL} — edit the canonical file and run neeve/scripts/shared_refs_sync.sh sync -->"

usage() {
  echo "Usage: $(basename "$0") <sync|check>" >&2
  exit 1
}

generated_content() {
  printf '%s\n' "${HEADER}"
  cat "${ROOT_DIR}/${CANONICAL}"
}

cmd_sync() {
  local dest
  for dest in "${DESTINATIONS[@]}"; do
    mkdir -p "$(dirname "${ROOT_DIR}/${dest}")"
    generated_content > "${ROOT_DIR}/${dest}"
    echo "Synced: ${dest}"
  done
}

cmd_check() {
  local dest failed=0
  if [[ ! -f "${ROOT_DIR}/${CANONICAL}" ]]; then
    echo "Missing canonical file: neeve/${CANONICAL}" >&2
    exit 1
  fi
  for dest in "${DESTINATIONS[@]}"; do
    if [[ ! -f "${ROOT_DIR}/${dest}" ]]; then
      echo "MISSING: ${dest} — run: neeve/scripts/shared_refs_sync.sh sync" >&2
      failed=1
      continue
    fi
    if diff -q <(generated_content) "${ROOT_DIR}/${dest}" >/dev/null; then
      echo "OK: ${dest}"
    else
      echo "DRIFT: ${dest} differs from canonical neeve/${CANONICAL} — edit the canonical, then run sync" >&2
      failed=1
    fi
  done
  exit "${failed}"
}

case "${1:-}" in
  sync)  cmd_sync ;;
  check) cmd_check ;;
  *)     usage ;;
esac
