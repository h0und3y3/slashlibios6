#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

[[ -s Makefile ]]
[[ -s control ]]
[[ -s Resources/Info.plist ]]
[[ -s .github/workflows/build.yml ]]

/usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' Resources/Info.plist >/dev/null 2>&1 || \
  python3 - <<'PY'
import plistlib
with open('Resources/Info.plist', 'rb') as f:
    p = plistlib.load(f)
assert p['MinimumOSVersion'] == '6.0', p.get('MinimumOSVersion')
assert p['CFBundleIdentifier'] == 'ru.slashlib.client'
assert p['CFBundleExecutable'] == 'Slashlib'
PY

grep -q '^TARGET := iphone:clang:9.3:6.0$' Makefile
grep -q '^ARCHS := armv7$' Makefile
grep -q '^Package: ru.slashlib.client$' control
for source in Sources/*.m; do [[ -s "$source" ]]; done
printf 'Build configuration looks consistent.\n'
