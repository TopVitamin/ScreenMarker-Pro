#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

PROJECT_PATH="${PROJECT_PATH:-${ROOT_DIR}/ScreenMarkerPro.xcodeproj}"
SCHEME="${SCHEME:-ScreenMarkerPro}"
APP_NAME="${APP_NAME:-ScreenMarkerPro}"
DISPLAY_NAME="${DISPLAY_NAME:-ScreenMarker Pro}"
INFO_PLIST_PATH="${INFO_PLIST_PATH:-${ROOT_DIR}/ScreenMarkerPro/Info.plist}"

BUILD_ROOT="${BUILD_ROOT:-${ROOT_DIR}/build/release}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${BUILD_ROOT}/DerivedData}"
ARCHIVE_PATH="${ARCHIVE_PATH:-${BUILD_ROOT}/${APP_NAME}.xcarchive}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-${BUILD_ROOT}/artifacts}"
APP_ARTIFACT_PATH="${APP_ARTIFACT_PATH:-${ARTIFACTS_DIR}/${APP_NAME}.app}"

read_plist_value() {
  local key="$1"
  /usr/libexec/PlistBuddy -c "Print :${key}" "${INFO_PLIST_PATH}"
}

VERSION="${VERSION:-$(read_plist_value CFBundleShortVersionString)}"
BUILD_NUMBER="${BUILD_NUMBER:-$(read_plist_value CFBundleVersion)}"
RELEASE_BASENAME="${RELEASE_BASENAME:-${APP_NAME}-${VERSION}}"

ZIP_PATH="${ZIP_PATH:-${ARTIFACTS_DIR}/${RELEASE_BASENAME}-macOS.zip}"
DMG_PATH="${DMG_PATH:-${ARTIFACTS_DIR}/${RELEASE_BASENAME}-macOS.dmg}"
PKG_PATH="${PKG_PATH:-${ARTIFACTS_DIR}/${RELEASE_BASENAME}-macOS.pkg}"
CHECKSUM_PATH="${CHECKSUM_PATH:-${ARTIFACTS_DIR}/SHA256SUMS.txt}"
METADATA_PATH="${METADATA_PATH:-${ARTIFACTS_DIR}/release-metadata.env}"

PRODUCT_BUNDLE_IDENTIFIER_OVERRIDE="${PRODUCT_BUNDLE_IDENTIFIER_OVERRIDE:-}"
DEVELOPMENT_TEAM_OVERRIDE="${DEVELOPMENT_TEAM_OVERRIDE:-}"
DEVELOPER_ID_APPLICATION="${DEVELOPER_ID_APPLICATION:-}"
DEVELOPER_ID_INSTALLER="${DEVELOPER_ID_INSTALLER:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

log() {
  printf '==> %s\n' "$*"
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

ensure_command() {
  command -v "$1" >/dev/null 2>&1 || fail "缺少命令: $1"
}

prepare_release_dirs() {
  rm -rf "${BUILD_ROOT}"
  mkdir -p "${ARTIFACTS_DIR}"
}

archive_app() {
  local signing_mode="${1:-unsigned}"
  local args=(
    xcodebuild
    -project "${PROJECT_PATH}"
    -scheme "${SCHEME}"
    -configuration Release
    -destination "generic/platform=macOS"
    -derivedDataPath "${DERIVED_DATA_PATH}"
    -archivePath "${ARCHIVE_PATH}"
    clean
    archive
  )

  if [[ "${signing_mode}" == "unsigned" ]]; then
    args+=(
      CODE_SIGNING_ALLOWED=NO
      CODE_SIGNING_REQUIRED=NO
      CODE_SIGN_IDENTITY=
    )
  else
    [[ -n "${PRODUCT_BUNDLE_IDENTIFIER_OVERRIDE}" ]] || fail "signed模式需要设置PRODUCT_BUNDLE_IDENTIFIER_OVERRIDE"
    [[ -n "${DEVELOPMENT_TEAM_OVERRIDE}" ]] || fail "signed模式需要设置DEVELOPMENT_TEAM_OVERRIDE"
    [[ -n "${DEVELOPER_ID_APPLICATION}" ]] || fail "signed模式需要设置DEVELOPER_ID_APPLICATION"
    args+=(
      CODE_SIGN_STYLE=Manual
      "PRODUCT_BUNDLE_IDENTIFIER=${PRODUCT_BUNDLE_IDENTIFIER_OVERRIDE}"
      "DEVELOPMENT_TEAM=${DEVELOPMENT_TEAM_OVERRIDE}"
      "CODE_SIGN_IDENTITY=${DEVELOPER_ID_APPLICATION}"
    )
  fi

  log "开始归档(${signing_mode})"
  "${args[@]}"
}

copy_app_from_archive() {
  local archive_app_path="${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app"
  [[ -d "${archive_app_path}" ]] || fail "归档产物不存在: ${archive_app_path}"

  rm -rf "${APP_ARTIFACT_PATH}"
  ditto "${archive_app_path}" "${APP_ARTIFACT_PATH}"
}

create_zip_from_app() {
  local app_path="$1"
  local zip_path="$2"
  rm -f "${zip_path}"
  ditto -c -k --keepParent "${app_path}" "${zip_path}"
}

create_dmg_from_app() {
  local app_path="$1"
  local dmg_path="$2"
  local staging_dir

  staging_dir="$(mktemp -d "${BUILD_ROOT}/dmg-staging.XXXXXX")"
  rm -f "${dmg_path}"
  ditto "${app_path}" "${staging_dir}/$(basename "${app_path}")"
  hdiutil create -volname "${DISPLAY_NAME}" -srcfolder "${staging_dir}" -ov -format UDZO "${dmg_path}" >/dev/null
  rm -rf "${staging_dir}"
}

create_pkg_from_app() {
  local app_path="$1"
  local pkg_path="$2"
  local args=(
    pkgbuild
    --component "${app_path}"
    --install-location /Applications
  )

  if [[ -n "${DEVELOPER_ID_INSTALLER}" ]]; then
    args+=(--sign "${DEVELOPER_ID_INSTALLER}")
  fi

  args+=("${pkg_path}")

  rm -f "${pkg_path}"
  "${args[@]}"
}

create_checksums() {
  : > "${CHECKSUM_PATH}"

  for artifact in "${ZIP_PATH}" "${DMG_PATH}" "${PKG_PATH}"; do
    [[ -f "${artifact}" ]] || continue
    shasum -a 256 "${artifact}" >> "${CHECKSUM_PATH}"
  done
}

write_release_metadata() {
  cat > "${METADATA_PATH}" <<EOF
APP_NAME='${APP_NAME}'
DISPLAY_NAME='${DISPLAY_NAME}'
VERSION='${VERSION}'
BUILD_NUMBER='${BUILD_NUMBER}'
DERIVED_DATA_PATH='${DERIVED_DATA_PATH}'
ARCHIVE_PATH='${ARCHIVE_PATH}'
APP_ARTIFACT_PATH='${APP_ARTIFACT_PATH}'
ZIP_PATH='${ZIP_PATH}'
DMG_PATH='${DMG_PATH}'
PKG_PATH='${PKG_PATH}'
CHECKSUM_PATH='${CHECKSUM_PATH}'
EOF
}
