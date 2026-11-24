#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "CONFIG ERROR: $*" >&2; exit 1; }

for required in Makefile control Info.plist Resources/Info.plist .github/workflows/build.yml build-theos.sh; do
  [[ -s "$required" ]] || fail "missing required file: $required"
done

python3 - <<'PY'
import plistlib
for path in ('Info.plist', 'Resources/Info.plist'):
    with open(path, 'rb') as f:
        p = plistlib.load(f)
    assert p.get('MinimumOSVersion') == '6.0', (path, p.get('MinimumOSVersion'))
    assert p.get('CFBundleIdentifier') == 'ru.slashlib.client'
    assert p.get('CFBundleExecutable') == 'Slashlib'
    assert p.get('CFBundlePackageType') == 'APPL'

with open('control', encoding='utf-8') as f:
    control = f.read()
assert 'Package: ru.slashlib.client' in control
assert 'Version: 0.3.0' in control
assert 'Architecture: iphoneos-arm' in control
assert 'Depends:' not in control, 'The app has no runtime package dependency; do not require modern firmware metapackage on iOS 6.'

with open('Makefile', encoding='utf-8') as f:
    makefile = f.read()
for needle in ('TARGET := iphone:clang:9.3:6.0', 'ARCHS := armv7', '$(wildcard Sources/*.m)', '$(THEOS_MAKE_PATH)/application.mk'):
    assert needle in makefile, needle

sources = sorted(__import__('glob').glob('Sources/*.m'))
assert sources, 'no Objective-C implementation files found'
assert 'Sources/main.m' in sources, 'main.m is missing'
for source in sources:
    assert __import__('os').path.getsize(source) > 0, f'empty source: {source}'

# Check that every local quoted header import resolves in Sources/.
import re, os
for source in sources:
    text = open(source, encoding='utf-8').read()
    for header in re.findall(r'^#import "([^"]+)"', text, re.M):
        if not os.path.isfile(os.path.join('Sources', header)):
            raise AssertionError(f'{source}: missing local header {header}')

# Ensure the newly ported subsystems are not merely listed in documentation.
required_sources = {
    'Sources/SLTiledPageView.m': ('setTilePaths:', 'purgeDecodedImages', 'reloadDecodedImages'),
    'Sources/SLPageStore.m': ('fetchURL:', 'thumbnailAtPath:', 'tilePathsAtPath:', 'trimCacheToBytes:'),
    'Sources/SLDiagnostics.m': ('SLMemoryMonitor', 'NSSetUncaughtExceptionHandler', 'markCleanExit'),
    'Sources/SLReaderSettingsViewController.m': ('SLReaderDim', 'SLReaderAutoHide'),
}
for path, needles in required_sources.items():
    data = open(path, encoding='utf-8').read()
    for needle in needles:
        assert needle in data, f'{path}: expected implementation token missing: {needle}'

assert 'SLReaderSettingsDelegate' in open('Sources/SLReaderSettingsViewController.h', encoding='utf-8').read()

# Verify every Objective-C implementation is actually part of the Xcode target,
# not merely present on disk. Theos uses the wildcard in Makefile separately.
project = open('Slashlib.xcodeproj/project.pbxproj', encoding='utf-8').read()
import re
phase_match = re.search(r'A10000000000000000000040 = \{isa = PBXSourcesBuildPhase;.*?files = \((.*?)\);', project)
assert phase_match, 'Xcode PBXSourcesBuildPhase not found'
phase_ids = set(re.findall(r'[A-F0-9]{24}', phase_match.group(1)))
file_refs = {m.group(1): m.group(2) for m in re.finditer(r'([A-F0-9]{24}) = \{isa = PBXFileReference; lastKnownFileType = sourcecode\.c\.objc; path = ([^;]+); sourceTree', project)}
build_refs = {m.group(1): m.group(2) for m in re.finditer(r'([A-F0-9]{24}) = \{isa = PBXBuildFile; fileRef = ([A-F0-9]{24});', project)}
compiled = {file_refs[build_refs[item]] for item in phase_ids if item in build_refs and build_refs[item] in file_refs}
missing = {os.path.basename(item) for item in sources} - compiled
assert not missing, 'Objective-C files missing from Xcode Sources phase: ' + ', '.join(sorted(missing))

reader = open('Sources/SLReaderViewController.m', encoding='utf-8').read()
for needle in ('SLPageStore fetchURL:', 'tilePathsAtPath:', 'renderPageAtIndex:', 'recalculateVerticalContentPreservingPage:', 'openReaderSettings', 'readerSettingsDidChange', 'SLReaderDim'):
    assert needle in reader, f'reader integration missing: {needle}'
settings = open('Sources/SLSettingsViewController.m', encoding='utf-8').read()
assert 'SLDiagnosticsViewController' in settings and 'SLPageStore clearCache' in settings
workflow = open('.github/workflows/build.yml', encoding='utf-8').read()
assert 'bash build-theos.sh' in workflow, 'workflow must invoke scripts through bash (no executable-bit dependency)'
assert 'sudo make' not in workflow and 'sudo bash build-theos.sh' not in workflow

print(f'Configuration OK: {len(sources)} Objective-C implementation files; iOS 6.0; armv7; SDK 9.3; streamed page cache, strip renderer, diagnostics and reader settings integrated.')
PY

# These scripts are intentionally invoked with bash by Actions, so executable
# permission bits in GitHub's web uploader are not required.
bash -n build-theos.sh
bash -n package-ipa.sh
bash -n package-deb.sh
