#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RENDERER="${ROOT_DIR}/scripts/context_render.py"

usage() {
  cat <<USAGE
Usage: $(basename "$0") <repo-name> <target-repo-path> [--check|--write]

  --check   Diff rendered context files against what's committed in target-repo-path (default)
  --write   Write rendered context files into target-repo-path

Examples:
  $(basename "$0") robin-ai ../robin-ai --check
  $(basename "$0") robin-ai ../robin-ai --write
USAGE
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

main() {
  require_cmd python3

  if [[ $# -lt 2 ]]; then
    usage
    exit 1
  fi

  local repo="$1" target="$2" mode="${3:---check}"

  case "${mode}" in
    --check)
      python3 "${RENDERER}" "${repo}" --check "${target}"
      ;;
    --write)
      python3 "${RENDERER}" "${repo}" --write "${target}"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
