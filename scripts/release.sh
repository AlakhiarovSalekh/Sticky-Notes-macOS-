#!/bin/bash
# Build a universal (arm64 + x86_64) release .app and package it for download.
# Produces build/StickyNotes-<version>-macos.zip and prints its SHA-256.
#
# Usage: scripts/release.sh v1.0.0
set -euo pipefail

TAG="${1:?usage: scripts/release.sh vX.Y.Z}"
VERSION="${TAG#v}"                       # strip leading "v" for Info.plist
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/Sticky Notes.app"
ZIP="$ROOT/build/StickyNotes-$TAG-macos.zip"

echo "==> Building universal release for $TAG"
ARCHS="arm64 x86_64" MARKETING_VERSION="$VERSION" BUILD_VERSION="$VERSION" \
    "$ROOT/scripts/bundle.sh" release

echo "==> Verifying architectures"
lipo -archs "$APP/Contents/MacOS/StickyNotes"

echo "==> Zipping bundle (ditto, preserves bundle + resource forks)"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> Done"
echo "    Asset:  $ZIP"
echo -n "    SHA256: "; shasum -a 256 "$ZIP" | awk '{print $1}'
echo -n "    Size:   "; du -h "$ZIP" | awk '{print $1}'
