#!/bin/bash
# Gera Resources/AppIcon.icns a partir de um PNG 1024×1024 (sips + iconutil, sem Xcode).
set -euo pipefail
cd "$(dirname "$0")/.."
SRC="${1:-Resources/icon-1024.png}"
[ -f "$SRC" ] || swift Scripts/make-icon.swift "$SRC"
SET="build/AppIcon.iconset"
rm -rf "$SET"; mkdir -p "$SET"
for s in 16 32 128 256 512; do
  sips -z $s $s "$SRC" --out "$SET/icon_${s}x${s}.png" > /dev/null
  sips -z $((s*2)) $((s*2)) "$SRC" --out "$SET/icon_${s}x${s}@2x.png" > /dev/null
done
iconutil -c icns "$SET" -o Resources/AppIcon.icns
rm -rf "$SET"
echo "✔ Resources/AppIcon.icns"
