#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
: "${THEOS:=$HOME/theos}"
export THEOS

if [[ ! -x "$THEOS/bin/nic.pl" || ! -x "$THEOS/toolchain/linux/iphone/bin/clang" ]]; then
  echo "Theos/toolchain missing. Run .github/workflows/build.yml or install Theos first." >&2
  exit 2
fi
if [[ ! -d "$THEOS/sdks/iPhoneOS9.3.sdk" ]]; then
  echo "Missing $THEOS/sdks/iPhoneOS9.3.sdk (iOS 9.3 SDK required)." >&2
  exit 2
fi

mkdir -p build
rm -f packages/*.ipa packages/*.deb 2>/dev/null || true

make clean
make package PACKAGE_FORMAT=ipa FINALPACKAGE=1 ADDITIONAL_OBJCFLAGS=-Wno-error
IPA="$(find packages -maxdepth 1 -type f -name '*.ipa' -print -quit)"
[[ -n "$IPA" ]] || { echo "Theos did not create an IPA." >&2; exit 3; }
cp "$IPA" build/Slashlib-theos-raw.ipa

# Theos' IPA packager may preserve the Debian install prefix as
# Payload/Applications/<App>.app. Normalize it to Apple's standard
# Payload/<App>.app layout so sideloading tools can read the archive.
IPA_TMP="$(mktemp -d)"
trap 'rm -rf "$IPA_TMP"' EXIT
unzip -q build/Slashlib-theos-raw.ipa -d "$IPA_TMP"
if [[ -d "$IPA_TMP/Payload/Applications/Slashlib.app" && ! -e "$IPA_TMP/Payload/Slashlib.app" ]]; then
  mv "$IPA_TMP/Payload/Applications/Slashlib.app" "$IPA_TMP/Payload/Slashlib.app"
  rmdir "$IPA_TMP/Payload/Applications"
fi
[[ -d "$IPA_TMP/Payload/Slashlib.app" ]] || {
  echo "Theos IPA does not contain Payload/Slashlib.app; archive layout is unexpected." >&2
  find "$IPA_TMP" -maxdepth 4 -print >&2
  exit 5
}
rm -f build/Slashlib.ipa
(cd "$IPA_TMP" && zip -qry "$ROOT/build/Slashlib.ipa" Payload)
rm -f build/Slashlib-theos-raw.ipa

make clean
make package PACKAGE_FORMAT=deb FINALPACKAGE=1 ADDITIONAL_OBJCFLAGS=-Wno-error
DEB="$(find packages -maxdepth 1 -type f -name '*.deb' -print -quit)"
[[ -n "$DEB" ]] || { echo "Theos did not create a DEB." >&2; exit 4; }
cp "$DEB" build/

# Basic package integrity checks.
unzip -t build/Slashlib.ipa >/dev/null
unzip -Z1 build/Slashlib.ipa | grep -q '^Payload/Slashlib.app/Info.plist$'
unzip -Z1 build/Slashlib.ipa | grep -q '^Payload/Slashlib.app/Slashlib$'
ar t "$DEB" >/dev/null

echo "Built packages:"
ls -lh build/Slashlib.ipa build/*.deb
