#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${ROOT_DIR}/prompts-src"

usage() {
  cat <<USAGE
Usage: $(basename "$0") <check|list|check-target TARGET_PATH>

Commands:
  check                   Verify every *.prompt.md has valid frontmatter (a 'description' key)
  list                    Print the discovered prompt names
  check-target TARGET_PATH
                          Diff TARGET_PATH/.github/prompts/*.prompt.md against
                          prompts-src/*.prompt.md. Fails if any installed
                          prompt has drifted from source, or if a source
                          prompt is missing from the target entirely.
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

check_target() {
  local target_dir="$1"
  local target_prompts_dir="${target_dir}/.github/prompts"
  local failed=0

  if [[ ! -d "${target_prompts_dir}" ]]; then
    echo "No .github/prompts/ in ${target_dir} — nothing installed there, nothing to check."
    return 0
  fi

  local prompts=()
  while IFS= read -r file; do
    prompts+=("${file}")
  done < <(discover_prompts)

  for prompt in "${prompts[@]}"; do
    local name installed_file
    name="$(basename "${prompt}")"
    installed_file="${target_prompts_dir}/${name}"
    if [[ ! -f "${installed_file}" ]]; then
      echo "MISSING: ${name} (present in prompts-src, not installed in ${target_prompts_dir})" >&2
      failed=1
      continue
    fi
    if diff -u "${prompt}" "${installed_file}" >/dev/null 2>&1; then
      echo "OK: ${name}"
    else
      echo "DRIFT: ${name} (installed copy differs from prompts-src/${name})" >&2
      diff -u "${prompt}" "${installed_file}" || true
      failed=1
    fi
  done

  return "${failed}"
}

main() {
  require_cmd find
  require_cmd sed
  require_cmd grep
  require_cmd diff

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
    check-target)
      local target_path="${2:-}"
      if [[ -z "${target_path}" ]]; then
        echo "check-target requires a TARGET_PATH argument" >&2
        usage
        exit 1
      fi
      check_target "${target_path}"
      exit $?
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
