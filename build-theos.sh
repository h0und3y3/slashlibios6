#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
: "${THEOS:=$HOME/theos}"
export THEOS
export THEOS_PACKAGE_DIR="$ROOT/packages"

fail() { echo "BUILD ERROR: $*" >&2; exit 1; }

[[ "$(id -u)" -ne 0 ]] || fail 'Do not run Theos/make as root; use the normal GitHub Actions runner user.'
command -v make >/dev/null 2>&1 || fail 'GNU make is missing.'
command -v unzip >/dev/null 2>&1 || fail 'unzip is missing.'
command -v zip >/dev/null 2>&1 || fail 'zip is missing.'
command -v dpkg-deb >/dev/null 2>&1 || fail 'dpkg-deb is missing.'
command -v file >/dev/null 2>&1 || fail 'file is missing.'
[[ -f "$THEOS/makefiles/common.mk" ]] || fail "Theos not found at $THEOS."
[[ -x "$THEOS/toolchain/linux/iphone/bin/clang" ]] || fail 'Theos iOS clang toolchain is missing.'
[[ -d "$THEOS/sdks/iPhoneOS9.3.sdk" ]] || fail "Missing $THEOS/sdks/iPhoneOS9.3.sdk."
[[ -s "$ROOT/Info.plist" ]] || fail 'Missing root Info.plist.'
[[ -s "$ROOT/control" ]] || fail 'Missing root control file.'

mkdir -p "$ROOT/build" "$THEOS_PACKAGE_DIR"
rm -f "$ROOT/build/Slashlib.ipa" \
      "$ROOT/build/ru.slashlib.client_0.3.0_iphoneos-arm.deb" \
      "$THEOS_PACKAGE_DIR"/*.ipa "$THEOS_PACKAGE_DIR"/*.deb

build_package() {
  local format="$1"
  echo "==> Building $format (iOS 6.0 deployment, armv7, iPhoneOS 9.3 SDK)"
  make clean
  make package PACKAGE_FORMAT="$format" FINALPACKAGE=1
}

# Theos' IPA package format stages Applications/ into Payload/.
build_package ipa
IPA="$(find "$THEOS_PACKAGE_DIR" -maxdepth 1 -type f -name '*.ipa' -print -quit)"
[[ -n "$IPA" && -s "$IPA" ]] || fail "Theos did not produce an IPA in $THEOS_PACKAGE_DIR."

IPA_TMP="$(mktemp -d)"
trap 'rm -rf "$IPA_TMP"' EXIT
unzip -q "$IPA" -d "$IPA_TMP"
APP="$IPA_TMP/Payload/Slashlib.app"
if [[ ! -d "$APP" && -d "$IPA_TMP/Payload/Applications/Slashlib.app" ]]; then
  APP="$IPA_TMP/Payload/Applications/Slashlib.app"
fi
[[ -d "$APP" ]] || { find "$IPA_TMP" -maxdepth 5 -print >&2; fail 'IPA does not contain Payload/Slashlib.app.'; }
[[ -s "$APP/Slashlib" ]] || fail 'Executable is missing from the IPA app bundle.'
[[ -s "$APP/Info.plist" ]] || fail 'Info.plist is missing from the IPA app bundle.'

python3 - "$APP/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], 'rb') as f:
    p = plistlib.load(f)
assert p.get('MinimumOSVersion') == '6.0', p.get('MinimumOSVersion')
assert p.get('CFBundleIdentifier') == 'ru.slashlib.client', p.get('CFBundleIdentifier')
assert p.get('CFBundleExecutable') == 'Slashlib', p.get('CFBundleExecutable')
PY

BIN_INFO="$(file "$APP/Slashlib")"
echo "$BIN_INFO"
case "$BIN_INFO" in
  *Mach-O*arm*) ;;
  *) fail "Expected an ARM Mach-O binary, got: $BIN_INFO" ;;
esac

# Normalize to the standard sideloadable IPA layout and give it a stable name.
rm -rf "$IPA_TMP/normalized"
mkdir -p "$IPA_TMP/normalized/Payload"
cp -a "$APP" "$IPA_TMP/normalized/Payload/Slashlib.app"
rm -f "$ROOT/build/Slashlib.ipa"
(cd "$IPA_TMP/normalized" && zip -qry "$ROOT/build/Slashlib.ipa" Payload)
unzip -tq "$ROOT/build/Slashlib.ipa"

# Build a separate rootful package for jailbroken ARMv7 devices.
build_package deb
DEB="$(find "$THEOS_PACKAGE_DIR" -maxdepth 1 -type f -name '*.deb' -print -quit)"
[[ -n "$DEB" && -s "$DEB" ]] || fail "Theos did not produce a DEB in $THEOS_PACKAGE_DIR."
cp "$DEB" "$ROOT/build/ru.slashlib.client_0.3.0_iphoneos-arm.deb"
dpkg-deb --info "$ROOT/build/ru.slashlib.client_0.3.0_iphoneos-arm.deb" >/dev/null
dpkg-deb --contents "$ROOT/build/ru.slashlib.client_0.3.0_iphoneos-arm.deb" | grep -q './Applications/Slashlib.app/Slashlib' \
  || fail 'DEB does not contain /Applications/Slashlib.app/Slashlib.'

printf '\nBuild completed. Output files:\n'
ls -lh "$ROOT/build/Slashlib.ipa" "$ROOT/build/ru.slashlib.client_0.3.0_iphoneos-arm.deb"
