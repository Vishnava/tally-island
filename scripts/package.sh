#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
build_root="${TALLY_BUILD_DIR:-$PWD/.build}"
if [[ "${TALLY_SKIP_BUILD:-0}" != 1 ]]; then ./scripts/build.sh; fi
package_root="${TALLY_DIST_DIR:-$PWD/dist}"
stage_root=$(mktemp -d "${TMPDIR:-/tmp}/tally-package.XXXXXX")
trap 'rm -rf "$stage_root"' EXIT
app="$stage_root/Tally Island.app"
mkdir -p "$package_root"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources" "$build_root"
cp "$build_root/bin/TallyIsland" "$app/Contents/MacOS/TallyIsland"
cp "$build_root/bin/tally" "$app/Contents/MacOS/tally"
cp docs/INTEGRATIONS.md "$app/Contents/Resources/INTEGRATIONS.md"
cp LICENSE "$app/Contents/Resources/LICENSE"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>TallyIsland</string>
<key>CFBundleIdentifier</key><string>io.github.vishnava.tally-island</string>
<key>CFBundleName</key><string>Tally Island</string>
<key>CFBundleDisplayName</key><string>Tally Island</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>NSHumanReadableCopyright</key><string>© 2026 Tally Island contributors. MIT License.</string>
</dict></plist>
PLIST
export CLANG_MODULE_CACHE_PATH="$build_root/modules"
swift scripts/icon.swift "$build_root/AppIcon.iconset"
iconutil -c icns "$build_root/AppIcon.iconset" -o "$app/Contents/Resources/AppIcon.icns"
# Finder may add metadata to a newly created bundle in a synced folder.
# Remove only FinderInfo on our generated bundle; never alter quarantine.
xattr -d com.apple.FinderInfo "$app" 2>/dev/null || true
codesign --force --sign - "$app/Contents/MacOS/tally"
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
archive="$package_root/Tally-Island-0.1.0-${TALLY_ARCH:-$(uname -m)}.zip"
ditto -c -k --sequesterRsrc --keepParent "$app" "$archive"
(cd "$package_root" && shasum -a 256 "$(basename "$archive")" > SHA256SUMS.txt)
ditto --norsrc --noextattr "$app" "$package_root/Tally Island.app"
echo "Packaged $archive (ad-hoc signed; not notarized)"
