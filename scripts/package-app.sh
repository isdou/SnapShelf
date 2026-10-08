#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
mode="${1:-debug}"

swift build -c "$mode"

app="$root/dist/暂存架.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$root/.build/$mode/Zancunjia" "$app/Contents/MacOS/Zancunjia"
if [[ "$mode" == release ]]; then
  xcrun strip -Sx "$app/Contents/MacOS/Zancunjia"
fi
cp "$root/Support/Info.plist" "$app/Contents/Info.plist"
if [[ ! -f "$root/Support/AppIcon.icns" ]]; then
  swift "$root/scripts/make-icon.swift" "$root/Support"
fi
cp "$root/Support/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"
codesign --force --sign - --entitlements "$root/Support/SnapShelf.entitlements" "$app"
echo "$app"
