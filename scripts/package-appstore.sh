#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

identity_app="3rd Party Mac Developer Application: Xiaohan Su (87GVTD226F)"
identity_pkg="3rd Party Mac Developer Installer: Xiaohan Su (87GVTD226F)"
profile="$root/Support/SnapShelfMacAppStore.provisionprofile"
entitlements="$root/Support/SnapShelf.entitlements"

[[ -f "$profile" ]] || { echo "missing $profile" >&2; exit 1; }
[[ -f "$entitlements" ]] || { echo "missing $entitlements" >&2; exit 1; }
[[ -f "$root/Support/AppIcon.icns" ]] || swift "$root/scripts/make-icon.swift" "$root/Support"

swift build -c release

app="$root/dist/SnapShelf.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$root/.build/release/Zancunjia" "$app/Contents/MacOS/Zancunjia"
xcrun strip -Sx "$app/Contents/MacOS/Zancunjia"
cp "$root/Support/Info.plist" "$app/Contents/Info.plist"
cp "$root/Support/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"
cp "$profile" "$app/Contents/embedded.provisionprofile"

shopt -s nullglob
bundles=("$root/.build/release"/*.bundle)
(( ${#bundles[@]} > 0 )) || { echo "missing SwiftPM resource bundles in .build/release" >&2; exit 1; }
for bundle in "${bundles[@]}"; do
  cp -R "$bundle" "$app/Contents/Resources/"
done
shopt -u nullglob

core_bundle="$app/Contents/Resources/Zancunjia_ZancunjiaCore.bundle"
[[ -d "$core_bundle" ]] || { echo "missing $core_bundle" >&2; exit 1; }
[[ -f "$core_bundle/Contents/Resources/en.lproj/Localizable.strings" ]] || {
  echo "missing English strings in $core_bundle" >&2
  exit 1
}
[[ -f "$core_bundle/Contents/Resources/zh-Hans.lproj/Localizable.strings" ]] || {
  echo "missing zh-Hans strings in $core_bundle" >&2
  exit 1
}

# Nested code first, then the app (no --deep).
while IFS= read -r nested; do
  codesign --force --options runtime --timestamp --sign "$identity_app" "$nested"
done < <(find "$app/Contents/Resources" -name '*.bundle' -type d)

codesign --force --options runtime --timestamp \
  --entitlements "$entitlements" \
  --sign "$identity_app" \
  "$app"

codesign --verify --deep --strict --verbose=2 "$app"
codesign -dvvv --entitlements :- "$app" >/dev/null

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$app/Contents/Info.plist")"
[[ "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || { echo "invalid CFBundleShortVersionString: $version" >&2; exit 1; }
[[ "$build" =~ ^[0-9]+$ ]] || { echo "invalid CFBundleVersion: $build" >&2; exit 1; }

pkg="$root/dist/SnapShelf.pkg"
rm -f "$pkg"
productbuild --component "$app" /Applications \
  --sign "$identity_pkg" \
  "$pkg"

pkgutil --check-signature "$pkg"
echo "$pkg"
echo "version=$version build=$build"
