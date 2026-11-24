#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP="build/Slashlib.app"
[ -d "$APP" ] || { echo "Не найдено $APP. Сначала соберите проект через xcodebuild." >&2; exit 1; }
command -v dpkg-deb >/dev/null 2>&1 || { echo "Нужен dpkg-deb (на macOS установите dpkg через Homebrew)." >&2; exit 1; }
ROOT="build/deb-root"
rm -rf "$ROOT"
mkdir -p "$ROOT/Applications" "$ROOT/DEBIAN"
cp -R "$APP" "$ROOT/Applications/Slashlib.app"
cat > "$ROOT/DEBIAN/control" <<'CONTROL'
Package: ru.slashlib.client
Name: Slashlib
Version: 0.3.0
Architecture: iphoneos-arm
Description: Unofficial Slashlib reader for iOS 6
Maintainer: Slashlib community <noreply@example.invalid>
Author: Slashlib community
Section: Applications
Depends: firmware (>= 6.0)
CONTROL
cat > "$ROOT/DEBIAN/postinst" <<'POST'
#!/bin/sh
if [ -x /usr/bin/uicache ]; then /usr/bin/uicache || true; fi
exit 0
POST
cat > "$ROOT/DEBIAN/postrm" <<'POST'
#!/bin/sh
if [ -x /usr/bin/uicache ]; then /usr/bin/uicache || true; fi
exit 0
POST
chmod 0755 "$ROOT/DEBIAN/postinst" "$ROOT/DEBIAN/postrm"
dpkg-deb -b "$ROOT" build/ru.slashlib.client_0.3.0_iphoneos-arm.deb
echo "Создан build/ru.slashlib.client_0.3.0_iphoneos-arm.deb"
