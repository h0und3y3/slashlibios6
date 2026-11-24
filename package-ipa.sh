#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP="build/Slashlib.app"
[ -d "$APP" ] || { echo "Не найдено $APP. Сначала соберите проект через xcodebuild." >&2; exit 1; }
rm -rf build/Payload
mkdir -p build/Payload
cp -R "$APP" build/Payload/Slashlib.app
(cd build && /usr/bin/zip -qry Slashlib.ipa Payload)
echo "Создан build/Slashlib.ipa (unsigned)"
