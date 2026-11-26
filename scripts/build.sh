#!/bin/sh
# Builds PiP Lock.app for Apple Silicon and Intel Macs, plus a release zip, into ./build
set -eu
cd "$(dirname "$0")/.."

APP="build/PiP Lock.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)

rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build/tmp

# Icon
swift scripts/make-icon.swift build/tmp/icon.png
ICONSET=build/tmp/AppIcon.iconset
mkdir -p "$ICONSET"
for s in 16 32 128 256; do
  sips -z $s $s build/tmp/icon.png --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z $((s * 2)) $((s * 2)) build/tmp/icon.png --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

# Binary
for arch in arm64 x86_64; do
  swiftc -Osize -target "$arch-apple-macos12" Sources/main.swift -o "build/tmp/PiPLock-$arch"
done
lipo -create build/tmp/PiPLock-arm64 build/tmp/PiPLock-x86_64 -output "$APP/Contents/MacOS/PiPLock"
strip -x "$APP/Contents/MacOS/PiPLock"

cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign "${SIGN_IDENTITY:--}" --options runtime "$APP"

(cd build && ditto -c -k --keepParent "PiP Lock.app" "PiP-Lock-$VERSION.zip")
rm -rf build/tmp
du -sh "$APP" "build/PiP-Lock-$VERSION.zip"
