#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

[[ -f "${METADATA_PATH}" ]] || fail "缺少release-metadata.env，请先运行scripts/package-release.sh"
source "${METADATA_PATH}"

ensure_command xcrun
ensure_command ditto
ensure_command hdiutil

[[ -n "${NOTARY_PROFILE}" ]] || fail "请先设置NOTARY_PROFILE"
[[ -d "${APP_ARTIFACT_PATH}" ]] || fail "待公证App不存在: ${APP_ARTIFACT_PATH}"

notary_zip="${ARTIFACTS_DIR}/${RELEASE_BASENAME}-notary-upload.zip"

log "提交App进行公证"
create_zip_from_app "${APP_ARTIFACT_PATH}" "${notary_zip}"
xcrun notarytool submit "${notary_zip}" --keychain-profile "${NOTARY_PROFILE}" --wait

log "装订App票据"
xcrun stapler staple "${APP_ARTIFACT_PATH}"

log "重建zip/dmg"
create_zip_from_app "${APP_ARTIFACT_PATH}" "${ZIP_PATH}"
create_dmg_from_app "${APP_ARTIFACT_PATH}" "${DMG_PATH}"

log "提交dmg进行公证"
xcrun notarytool submit "${DMG_PATH}" --keychain-profile "${NOTARY_PROFILE}" --wait
xcrun stapler staple "${DMG_PATH}"

if [[ -f "${PKG_PATH}" ]]; then
  log "提交pkg进行公证"
  xcrun notarytool submit "${PKG_PATH}" --keychain-profile "${NOTARY_PROFILE}" --wait
  xcrun stapler staple "${PKG_PATH}"
fi

rm -f "${notary_zip}"
create_checksums
write_release_metadata

cat <<EOF
公证完成:
- App: ${APP_ARTIFACT_PATH}
- ZIP: ${ZIP_PATH}
- DMG: ${DMG_PATH}
EOF

if [[ -f "${PKG_PATH}" ]]; then
  printf '%s\n' "- PKG: ${PKG_PATH}"
fi
