# Slashlib iOS 6 (Objective-C / Theos)

Legacy iOS application port targeting **iOS 6.0+ / ARMv7**. The project is built with Theos on
Linux and the GitHub Actions workflow produces an IPA and a rootful jailbreak DEB.

## Build on GitHub

1. Upload the contents of this archive to the root of a GitHub repository.
2. Open **Actions** and run **Build Slashlib iOS 6 (Theos on Linux)**, or push to `main`/`master`.
3. Download the `Slashlib-iOS6-IPA-DEB` artifact. The artifact includes `Slashlib.ipa`, the DEB,
   and `build.log` (if the build fails, the log is still uploaded).

The workflow installs system packages with `sudo`, installs and runs Theos as the normal runner
user, and invokes shell scripts through `bash` so GitHub's executable-bit handling does not block
execution.

## Targets

- Deployment target: iOS 6.0
- Architecture: ARMv7
- SDK: iPhoneOS 9.3 (supported by Theos' Linux iOS toolchain)
- Build system: Theos
- Outputs: sideloadable/enterprise-signed-later `Slashlib.ipa` (unsigned) and rootful
  `ru.slashlib.client_0.3.0_iphoneos-arm.deb`

The IPA is not code-signed by this workflow. Install it using a compatible signing/sideloading
method or jailbreak tooling as appropriate. The DEB is intended for a rootful jailbreak and is not
an App Store package.

## Current port status

Search, catalog, title/chapter navigation, favorites/history/bookmarks, API/auth/sync modules,
reader basics, lazy page loading, streaming disk page cache, ImageIO downsampling, reader settings
and diagnostics are represented in Objective-C. Several behaviors remain partial; see [`PORT_AUDIT.md`](PORT_AUDIT.md)
for the exact scope and known gaps. A successful Actions run is required to verify compilation.

## Long-page strip renderer (iOS 6 / ARMv7)

The reader now uses `SLPageStore` to generate a bounded ImageIO thumbnail for tall pages and persist it as 768-pixel JPEG strips. `SLTiledPageView` lays those strips vertically, allowing the outer reader scroll view to move through long webtoon pages without keeping one full-height decoded bitmap alive. Strips are cached on disk and off-screen page image objects can be purged after a memory warning.

Important platform limitation: iOS 6 ImageIO does not expose a public region/tile decoder. This implementation therefore downsamples the longest image edge to 3072 pixels in energy-saving mode or 4096 pixels otherwise, then slices that bounded image into strips. It is a memory-bounded strip renderer, not native-resolution region decoding. Normal single-page mode continues to use a single aspect-fit image.

Static verification: `bash scripts/check-build-config.sh` validates the source wiring and build configuration. The GitHub Actions build is the authoritative compile test; no successful IPA/DEB build is claimed until that workflow completes.
