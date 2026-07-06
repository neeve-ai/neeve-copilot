#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${ROOT_DIR}/prompts-src"

usage() {
  cat <<USAGE
Usage: $(basename "$0") <check|list>

Commands:
  check   Verify every *.prompt.md has valid frontmatter (a 'description' key)
  list    Print the discovered prompt names
USAGE
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

discover_prompts() {
  find "${SRC_DIR}" -maxdepth 1 -type f -name '*.prompt.md' | LC_ALL=C sort
}

check_one() {
  local file="$1"
  local name
  name="$(basename "${file}" .prompt.md)"

  if ! head -1 "${file}" | grep -q '^---$'; then
    echo "Missing frontmatter delimiter in: ${file}" >&2
    return 1
  fi

  if ! sed -n '2,10p' "${file}" | grep -q '^description:'; then
    echo "Missing 'description:' frontmatter key in: ${file}" >&2
    return 1
  fi

  echo "OK: ${name}"
}

main() {
  require_cmd find
  require_cmd sed
  require_cmd grep

  if [[ ! -d "${SRC_DIR}" ]]; then
    echo "Missing prompts source directory: ${SRC_DIR}" >&2
    exit 1
  fi

  local prompts=()
  while IFS= read -r file; do
    prompts+=("${file}")
  done < <(discover_prompts)

  if [[ ${#prompts[@]} -eq 0 ]]; then
    echo "No prompts found under ${SRC_DIR}" >&2
    exit 1
  fi

  local cmd="${1:-}"
  case "${cmd}" in
    check)
      local failed=0
      for prompt in "${prompts[@]}"; do
        check_one "${prompt}" || failed=1
      done
      exit "${failed}"
      ;;
    list)
      for prompt in "${prompts[@]}"; do
        basename "${prompt}" .prompt.md
      done
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
