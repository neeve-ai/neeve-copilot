#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${ROOT_DIR}/hooks-src"

usage() {
  cat <<USAGE
Usage: $(basename "$0") <check-target TARGET_PATH>

Commands:
  check-target TARGET_PATH
                          Diff TARGET_PATH/.github/hooks/ against
                          hooks-src/ (hooks.json + scripts/*.sh). If
                          TARGET_PATH has no .github/hooks/, that's not an
                          error — hooks are only installed where a repo's
                          context-src yaml sets spec_based_development: true.
USAGE
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

check_target() {
  local target_dir="$1"
  local target_hooks_dir="${target_dir}/.github/hooks"
  local failed=0

  if [[ ! -d "${target_hooks_dir}" ]]; then
    echo "No .github/hooks/ in ${target_dir} — nothing installed there, nothing to check."
    return 0
  fi

  if [[ ! -f "${target_hooks_dir}/hooks.json" ]]; then
    echo "MISSING: hooks.json (present in hooks-src as baseline.hooks.json, not installed in ${target_hooks_dir})" >&2
    failed=1
  elif diff -u "${SRC_DIR}/baseline.hooks.json" "${target_hooks_dir}/hooks.json" >/dev/null 2>&1; then
    echo "OK: hooks.json"
  else
    echo "DRIFT: hooks.json (installed copy differs from hooks-src/baseline.hooks.json)" >&2
    diff -u "${SRC_DIR}/baseline.hooks.json" "${target_hooks_dir}/hooks.json" || true
    failed=1
  fi

  for script in "${SRC_DIR}"/scripts/*.sh; do
    local name installed_file
    name="$(basename "${script}")"
    installed_file="${target_hooks_dir}/scripts/${name}"
    if [[ ! -f "${installed_file}" ]]; then
      echo "MISSING: scripts/${name} (present in hooks-src, not installed in ${target_hooks_dir}/scripts)" >&2
      failed=1
      continue
    fi
    if diff -u "${script}" "${installed_file}" >/dev/null 2>&1; then
      echo "OK: scripts/${name}"
    else
      echo "DRIFT: scripts/${name} (installed copy differs from hooks-src/scripts/${name})" >&2
      diff -u "${script}" "${installed_file}" || true
      failed=1
    fi
  done

  return "${failed}"
}

main() {
  require_cmd diff

  if [[ ! -d "${SRC_DIR}" ]]; then
    echo "Missing hooks source directory: ${SRC_DIR}" >&2
    exit 1
  fi

  local cmd="${1:-}"
  case "${cmd}" in
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
