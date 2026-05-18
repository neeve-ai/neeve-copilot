#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${ROOT_DIR}/skills-src"
ZIP_DIR="${ROOT_DIR}/zips"
SKILLS=()
shopt -s nullglob

usage() {
  cat <<USAGE
Usage: $(basename "$0") <check|pack>

Commands:
  check   Verify zips and skills-src are in sync (content-level)
  pack    Rebuild zips from skills-src
USAGE
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

discover_skills() {
  SKILLS=()
  while IFS= read -r dir; do
    SKILLS+=("$(basename "${dir}")")
  done < <(find "${SRC_DIR}" -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort)

  if [[ ${#SKILLS[@]} -eq 0 ]]; then
    echo "No skills found under ${SRC_DIR}" >&2
    exit 1
  fi
}

contains_skill() {
  local name="$1"
  local skill
  for skill in "${SKILLS[@]}"; do
    if [[ "${skill}" == "${name}" ]]; then
      return 0
    fi
  done
  return 1
}

validate_layout() {
  if [[ ! -d "${SRC_DIR}" ]]; then
    echo "Missing skills source directory: ${SRC_DIR}" >&2
    exit 1
  fi
  if [[ ! -d "${ZIP_DIR}" ]]; then
    echo "Missing zip directory: ${ZIP_DIR}" >&2
    exit 1
  fi

  for skill in "${SKILLS[@]}"; do
    if [[ ! -d "${SRC_DIR}/${skill}" ]]; then
      echo "Missing source directory: ${SRC_DIR}/${skill}" >&2
      exit 1
    fi
    if [[ ! -f "${SRC_DIR}/${skill}/SKILL.md" ]]; then
      echo "Missing SKILL.md in: ${SRC_DIR}/${skill}" >&2
      exit 1
    fi
    if [[ ! -f "${ZIP_DIR}/${skill}.zip" ]]; then
      echo "Missing zip archive: ${ZIP_DIR}/${skill}.zip" >&2
      exit 1
    fi
  done

  local zip_file zip_name
  for zip_file in "${ZIP_DIR}"/*.zip; do
    zip_name="$(basename "${zip_file}" .zip)"
    if ! contains_skill "${zip_name}"; then
      echo "Stale zip archive not represented in skills-src: ${zip_file}" >&2
      exit 1
    fi
  done
}

compare_one() {
  local skill="$1"
  local zip_file="${ZIP_DIR}/${skill}.zip"
  local src_skill_dir="${SRC_DIR}/${skill}"
  local tmp_dir

  tmp_dir="$(mktemp -d)"

  unzip -q "${zip_file}" -d "${tmp_dir}/unzipped"

  if [[ ! -d "${tmp_dir}/unzipped/${skill}" ]]; then
    echo "Archive ${zip_file} is missing top-level directory '${skill}/'" >&2
    rm -rf "${tmp_dir}"
    exit 1
  fi

  if ! diff -ru "${src_skill_dir}" "${tmp_dir}/unzipped/${skill}" >/dev/null; then
    echo "Out of sync: ${skill}" >&2
    diff -ru "${src_skill_dir}" "${tmp_dir}/unzipped/${skill}" || true
    rm -rf "${tmp_dir}"
    exit 1
  fi

  rm -rf "${tmp_dir}"
  echo "OK: ${skill}"
}

pack_one() {
  local skill="$1"
  local out_file="${ZIP_DIR}/${skill}.zip"
  local tmp_dir tmp_zip

  tmp_dir="$(mktemp -d)"
  tmp_zip="${tmp_dir}/${skill}.zip"

  (
    cd "${SRC_DIR}"
    # File list is sorted for stable archive structure.
    find "${skill}" -type f | LC_ALL=C sort | zip -X -q "${tmp_zip}" -@
  )

  mv "${tmp_zip}" "${out_file}"
  rm -rf "${tmp_dir}"
  echo "Packed: ${skill}.zip"
}

prune_stale_zips() {
  local zip_file zip_name
  for zip_file in "${ZIP_DIR}"/*.zip; do
    zip_name="$(basename "${zip_file}" .zip)"
    if ! contains_skill "${zip_name}"; then
      rm -f "${zip_file}"
      echo "Removed stale zip: ${zip_name}.zip"
    fi
  done
}

main() {
  require_cmd unzip
  require_cmd zip
  require_cmd diff
  require_cmd find
  discover_skills
  validate_layout

  local cmd="${1:-}"
  case "${cmd}" in
    check)
      for skill in "${SKILLS[@]}"; do
        compare_one "${skill}"
      done
      ;;
    pack)
      prune_stale_zips
      for skill in "${SKILLS[@]}"; do
        pack_one "${skill}"
      done
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
