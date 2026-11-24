#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
: "${THEOS:=$HOME/theos}"
export THEOS
export THEOS_PACKAGE_DIR="$ROOT/packages"

fail() { echo "BUILD ERROR: $*" >&2; exit 1; }

[[ "$(id -u)" -ne 0 ]] || fail 'Do not run Theos/make as root.'
command -v make      >/dev/null 2>&1 || fail 'GNU make is missing.'
command -v dpkg-deb  >/dev/null 2>&1 || fail 'dpkg-deb is missing.'
[[ -f "$THEOS/makefiles/common.mk" ]]                        || fail "Theos not found at $THEOS."
[[ -x "$THEOS/toolchain/linux/iphone/bin/clang" ]]           || fail 'Theos iOS clang toolchain is missing.'
[[ -d "$THEOS/sdks/iPhoneOS9.3.sdk" ]]                       || fail "Missing $THEOS/sdks/iPhoneOS9.3.sdk."
[[ -s "$ROOT/Info.plist" ]]                                  || fail 'Missing root Info.plist.'
[[ -s "$ROOT/control" ]]                                     || fail 'Missing root control file.'

mkdir -p "$ROOT/build" "$THEOS_PACKAGE_DIR"
# build/ must exist before the caller pipes into build/build.log via tee
rm -f "$ROOT/build/ru.slashlib.client_0.3.0_iphoneos-arm.deb" \
      "$THEOS_PACKAGE_DIR"/*.deb

echo "==> Building DEB (iOS 6.0 / armv7 / iPhoneOS 9.3 SDK)"
make clean
make package PACKAGE_FORMAT=deb FINALPACKAGE=1

DEB="$(find "$THEOS_PACKAGE_DIR" -maxdepth 1 -type f -name '*.deb' -print -quit)"
[[ -n "$DEB" && -s "$DEB" ]] || fail "Theos did not produce a DEB in $THEOS_PACKAGE_DIR."

cp "$DEB" "$ROOT/build/ru.slashlib.client_0.3.0_iphoneos-arm.deb"
dpkg-deb --info     "$ROOT/build/ru.slashlib.client_0.3.0_iphoneos-arm.deb" >/dev/null
dpkg-deb --contents "$ROOT/build/ru.slashlib.client_0.3.0_iphoneos-arm.deb" \
  | grep -q './Applications/Slashlib.app/Slashlib' \
  || fail 'DEB does not contain /Applications/Slashlib.app/Slashlib.'

printf '\nBuild completed:\n'
ls -lh "$ROOT/build/ru.slashlib.client_0.3.0_iphoneos-arm.deb"
