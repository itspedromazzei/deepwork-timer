#!/bin/bash
# Compila em release e monta build/Deepwork Timer.app (sem Xcode).
# Uso: Scripts/build-app.sh [--open]
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release 2>&1 | grep -vE "should be located" || true
BIN=".build/release/DeepworkTimer"
[ -x "$BIN" ] || { echo "binário não encontrado em $BIN"; exit 1; }

APP="build/Deepwork Timer.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/pt-BR.lproj"
cp "$BIN" "$APP/Contents/MacOS/DeepworkTimer"
cp Resources/Info.plist "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"
if [ -f Resources/AppIcon.icns ]; then
  cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
fi

plutil -lint "$APP/Contents/Info.plist" > /dev/null
codesign --force --deep --sign - "$APP" 2>&1 | grep -v "replacing existing signature" || true

echo "✔ $APP ($(du -sh "$APP" | cut -f1))"
if [ "${1:-}" = "--open" ]; then
  open "$APP"
fi
