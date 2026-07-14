#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Two skill roots: org-level (product-agnostic SDLC skills) and per-product
# (e.g. robin's neeve-dls / ot-building-automation). Skill names must be
# unique across roots — discover_skills fails loudly on a collision.
SRC_ROOTS=("${ROOT_DIR}/skills-src")
for product_dir in "${ROOT_DIR}"/products/*/; do
  [[ -d "${product_dir}skills-src" ]] && SRC_ROOTS+=("${product_dir}skills-src")
done
ZIP_DIR="${SKILLS_ZIP_DIR:-${ROOT_DIR}/dist/zips}"
SKILLS=()

skill_src_dir() {
  local name="$1" root
  for root in "${SRC_ROOTS[@]}"; do
    if [[ -d "${root}/${name}" ]]; then
      echo "${root}/${name}"
      return 0
    fi
  done
  return 1
}
shopt -s nullglob

usage() {
  cat <<USAGE
Usage: $(basename "$0") <check|pack|check-target TARGET_PATH>

Commands:
  check                   Verify skills-src can be packaged into valid zip archives
  pack                    Build zip archives from skills-src
  check-target TARGET_PATH
                          Diff TARGET_PATH/.github/skills/<skill> against
                          skills-src/<skill> for every skill actually
                          installed there (skills not present in the target
                          are skipped, not an error — not every repo installs
                          every skill). Fails if any installed copy has
                          drifted from source.
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
  local root name
  for root in "${SRC_ROOTS[@]}"; do
    [[ -d "${root}" ]] || continue
    while IFS= read -r dir; do
      name="$(basename "${dir}")"
      if contains_skill "${name}"; then
        echo "Skill name collision across roots: ${name}" >&2
        exit 1
      fi
      SKILLS+=("${name}")
    done < <(find "${root}" -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort)
  done
  if [[ ${#SKILLS[@]} -eq 0 ]]; then
    echo "No skills found under: ${SRC_ROOTS[*]}" >&2
    exit 1
  fi

  # Stable overall order regardless of which root a skill lives in.
  local sorted=()
  while IFS= read -r name; do
    sorted+=("${name}")
  done < <(printf '%s\n' "${SKILLS[@]}" | LC_ALL=C sort)
  SKILLS=("${sorted[@]}")
}

contains_skill() {
  local name="$1"
  local skill
  [[ ${#SKILLS[@]} -eq 0 ]] && return 1
  for skill in "${SKILLS[@]}"; do
    if [[ "${skill}" == "${name}" ]]; then
      return 0
    fi
  done
  return 1
}

validate_layout() {
  if [[ ! -d "${SRC_ROOTS[0]}" ]]; then
    echo "Missing skills source directory: ${SRC_ROOTS[0]}" >&2
    exit 1
  fi

  local skill src
  for skill in "${SKILLS[@]}"; do
    if ! src="$(skill_src_dir "${skill}")"; then
      echo "Missing source directory for skill: ${skill}" >&2
      exit 1
    fi
    if [[ ! -f "${src}/SKILL.md" ]]; then
      echo "Missing SKILL.md in: ${src}" >&2
      exit 1
    fi
  done
}

compare_one() {
  local skill="$1" zip_file="$2"
  local src_skill_dir
  src_skill_dir="$(skill_src_dir "${skill}")"
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
  local skill="$1" out_dir="$2"
  local out_file="${out_dir}/${skill}.zip"
  local tmp_dir tmp_zip

  tmp_dir="$(mktemp -d)"
  tmp_zip="${tmp_dir}/${skill}.zip"

  (
    cd "$(dirname "$(skill_src_dir "${skill}")")"
    # File list is sorted for stable archive structure.
    find "${skill}" -type f | LC_ALL=C sort | zip -X -q "${tmp_zip}" -@
  )

  mv "${tmp_zip}" "${out_file}"
  rm -rf "${tmp_dir}"
  echo "Packed: ${skill}.zip"
}

check_target() {
  local target_dir="$1"
  local target_skills_dir="${target_dir}/.github/skills"
  local failed=0
  local found_any=0

  if [[ ! -d "${target_skills_dir}" ]]; then
    echo "No .github/skills/ in ${target_dir} — nothing installed there, nothing to check."
    return 0
  fi

  for skill in "${SKILLS[@]}"; do
    local installed_dir="${target_skills_dir}/${skill}"
    [[ -d "${installed_dir}" ]] || continue
    found_any=1
    local src_dir
    src_dir="$(skill_src_dir "${skill}")"
    if diff -ru "${src_dir}" "${installed_dir}" >/dev/null 2>&1; then
      echo "OK: ${skill}"
    else
      echo "DRIFT: ${skill} (installed copy differs from ${src_dir})" >&2
      diff -ru "${src_dir}" "${installed_dir}" || true
      failed=1
    fi
  done

  if [[ "${found_any}" -eq 0 ]]; then
    echo "No known skills found installed under ${target_skills_dir}."
  fi

  return "${failed}"
}

prune_stale_zips() {
  [[ -d "${ZIP_DIR}" ]] || return 0

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
      local tmp_zip_dir
      tmp_zip_dir="$(mktemp -d)"
      for skill in "${SKILLS[@]}"; do
        pack_one "${skill}" "${tmp_zip_dir}"
        compare_one "${skill}" "${tmp_zip_dir}/${skill}.zip"
      done
      rm -rf "${tmp_zip_dir}"
      ;;
    pack)
      mkdir -p "${ZIP_DIR}"
      prune_stale_zips
      for skill in "${SKILLS[@]}"; do
        pack_one "${skill}" "${ZIP_DIR}"
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
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
