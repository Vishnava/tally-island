#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
build_root="${TALLY_BUILD_DIR:-$PWD/.build}"
mkdir -p "$build_root/modules" "$build_root/bin"
export CLANG_MODULE_CACHE_PATH="$build_root/modules"
# Direct compilation keeps this dependency-free project usable with Command Line Tools alone.
swiftc -O -swift-version 5 -target "${TALLY_ARCH:-$(uname -m)}-apple-macosx14.0" \
  -emit-library -static -emit-module -module-name TallyCore \
  Sources/TallyCore/Core.swift -emit-module-path "$build_root/TallyCore.swiftmodule" -o "$build_root/libTallyCore.a"
swiftc -O -swift-version 5 -target "${TALLY_ARCH:-$(uname -m)}-apple-macosx14.0" \
  -parse-as-library -I "$build_root" -L "$build_root" -lTallyCore \
  Sources/TallyIsland/*.swift -o "$build_root/bin/TallyIsland"
swiftc -O -swift-version 5 -target "${TALLY_ARCH:-$(uname -m)}-apple-macosx14.0" \
  -I "$build_root" -L "$build_root" -lTallyCore Sources/tally/main.swift -o "$build_root/bin/tally"
echo "Built $build_root/bin/TallyIsland and tally"
