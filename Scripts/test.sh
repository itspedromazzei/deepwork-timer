#!/bin/bash
# Roda os testes do DeepworkCore com Swift Testing usando só as Command Line Tools.
# O SwiftPM das CLT não aponta para Testing.framework nem para lib_TestingInterop.dylib sozinho.
set -euo pipefail
cd "$(dirname "$0")/.."
CLT="$(xcode-select -p)"
FW="$CLT/Library/Developer/Frameworks"
LIB="$CLT/Library/Developer/usr/lib"
exec swift test \
  -Xswiftc "-F$FW" \
  -Xlinker "-F$FW" \
  -Xlinker -rpath -Xlinker "$FW" \
  -Xlinker -rpath -Xlinker "$LIB" \
  "$@"
