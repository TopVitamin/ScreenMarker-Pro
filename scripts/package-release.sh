#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

signing_mode="unsigned"
create_pkg=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --signed)
      signing_mode="signed"
      ;;
    --unsigned)
      signing_mode="unsigned"
      ;;
    --with-pkg)
      create_pkg=1
      ;;
    *)
      fail "未知参数: $1"
      ;;
  esac
  shift
done

ensure_command xcodebuild
ensure_command ditto
ensure_command hdiutil
ensure_command pkgbuild
ensure_command shasum

prepare_release_dirs
archive_app "${signing_mode}"
copy_app_from_archive

log "生成zip"
create_zip_from_app "${APP_ARTIFACT_PATH}" "${ZIP_PATH}"

log "生成dmg"
create_dmg_from_app "${APP_ARTIFACT_PATH}" "${DMG_PATH}"

if [[ ${create_pkg} -eq 1 ]]; then
  log "生成pkg"
  create_pkg_from_app "${APP_ARTIFACT_PATH}" "${PKG_PATH}"
fi

create_checksums
write_release_metadata

cat <<EOF
Release产物已生成:
- App: ${APP_ARTIFACT_PATH}
- ZIP: ${ZIP_PATH}
- DMG: ${DMG_PATH}
EOF

if [[ ${create_pkg} -eq 1 ]]; then
  printf '%s\n' "- PKG: ${PKG_PATH}"
fi

printf '%s\n' "- SHA256: ${CHECKSUM_PATH}"
