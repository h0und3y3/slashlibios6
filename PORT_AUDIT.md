# Slashlib iOS 6 port audit

This is a compatibility port in progress, not a claim of feature parity with the Swift app.
The source archive contains 19 Swift files. The Objective-C target currently contains 17 `.m`
implementation files. The port deliberately targets iOS 6.0 / armv7 and uses manual reference
counting; no Swift runtime is used.

## This iteration

### PageStore (`SLPageStore`)
- URL cache files are keyed by SHA-1 and stored in `Library/Caches/SlashlibPages`.
- Network response bytes are streamed through `NSURLConnectionDataDelegate` into a temporary
  file, then atomically moved into the cache. This avoids accumulating the complete response in
  an `NSData` object.
- The reader lazily requests the visible page and its immediate neighbors; it does not launch a request for every chapter page at once.
- ImageIO creates a downsampled thumbnail with orientation transform before the reader displays it. Off-screen decoded page images are dropped after a memory warning and can be decoded again from the disk cache.
- Cache size accounting, least-recently-used trimming and manual cache clearing are available.
- This is not yet a pixel-perfect port of the Swift strip renderer: it downsamples the complete
  image to a bounded thumbnail, rather than decoding only visible horizontal strips.

### Diagnostics (`SLDiagnostics` / `SLMemoryMonitor`)
- Records app version, device identifier, iOS version, physical RAM and current resident memory.
- Keeps a bounded event log in Documents and logs memory warnings.
- Clears the transient cover-image cache on memory warning.
- Installs an uncaught Objective-C exception handler and a minimal POSIX fatal-signal marker.
- Fatal-signal context cannot safely produce a full symbolic stack; the report explicitly says so.
- Detects a prior launch without a clean-termination marker. iOS force-kill cannot be intercepted.

### Reader settings (`SLReaderSettingsViewController`)
- Adds a legacy UIKit settings panel suitable for iOS 6 (no UIStackView or modern appearance APIs).
- Supports scroll/page mode, page background, dim overlay, RTL order, auto-hide navigation bar,
  and keep-awake preference. The main Account screen still owns global theme selection; the original
  reader-panel quick theme selector and all original reader options are not yet fully mirrored.
- Settings are persisted in NSUserDefaults and applied to the current reader.

### Integration
- Reader image requests now go through the disk cache and ImageIO downsampling path.
- Account settings expose diagnostics and a page-cache clear action.
- App startup installs diagnostics; clean exit is marked on application termination.

## Remaining parity work

The following areas still require source-by-source porting and behavioral verification against the
original Swift implementation:

- Full horizontal-strip/tile renderer from `PageStore.swift`. The current implementation lazily loads pages and downscales each complete image; very tall source pages may lose detail because they are not yet decoded as independently visible strips.
- Full download queue semantics, pause/resume/retry, integrity checks and offline manifest migration.
- All original catalog/home filters, sorting, recommendations and source-specific behavior.
- Full auth/session refresh and all API response/error edge cases.
- Gist conflict resolution, tombstones and schema migration tests against actual exported Swift data.
- All theme/animation/power-profile behavior and diagnostics UI details.
- End-to-end tests on an actual iOS 6 ARMv7 device.

## Validation performed in this workspace

- `bash -n` on the build and packaging scripts.
- `scripts/check-build-config.sh`: plist structure, deployment target, architecture, source files,
  local imports and integration markers.
- ZIP integrity and package workflow configuration are checked when the archive is produced.

No iOS SDK or Theos toolchain is installed in this workspace, so Objective-C compilation and device
execution are **not** claimed as verified here. GitHub Actions must perform the actual compile.

## Long-page renderer follow-up

- Added `SLTiledPageView` and `SLPageStore.tilePathsAtPath:maxPixelSize:tilePixelHeight:`.
- Tall vertical pages are converted to a bounded ImageIO thumbnail and persisted as 768-pixel JPEG strips.
- The reader keeps the source path on each page view so strips can be regenerated after decoded images are purged.
- The cache size calculation now walks nested strip directories.
- Xcode project source phase and Theos wildcard both include the new renderer.
- Limitation: ImageIO on iOS 6 has no public region decode API; the renderer downsamples to a 3072/4096-pixel longest edge before strip generation. Native-resolution tiles are not claimed.
