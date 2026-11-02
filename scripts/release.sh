#!/usr/bin/env bash
#
# Aero — Developer ID release: archive → export → notarize → staple → verify.
#
# One-time setup (after the Apple Developer Program approval comes through):
#   1. Add your Apple ID in Xcode → Settings → Accounts, then create a
#      "Developer ID Application" certificate (Manage Certificates → +).
#   2. Store notarization credentials once (uses the app-specific password):
#        xcrun notarytool store-credentials "aero-notary" \
#          --apple-id "YOUR_APPLE_ID_EMAIL" \
#          --team-id "59MJ8J2KF3" \
#          --password "APP_SPECIFIC_PASSWORD"
#
# Then just run:  ./scripts/release.sh
#
set -euo pipefail

PROJECT="aero.xcodeproj"
SCHEME="aero"
CONFIG="Release"
KEYCHAIN_PROFILE="aero-notary"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/build"
ARCHIVE="$BUILD_DIR/aero.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
EXPORT_OPTS="$ROOT/scripts/ExportOptions.plist"

cd "$ROOT"

echo "==> Cleaning previous build artifacts"
rm -rf "$ARCHIVE" "$EXPORT_DIR"

echo "==> Archiving ($CONFIG)"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -archivePath "$ARCHIVE"

echo "==> Exporting with Developer ID"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$EXPORT_OPTS" \
  -exportPath "$EXPORT_DIR"

APP="$EXPORT_DIR/aero.app"
ZIP="$EXPORT_DIR/aero.zip"

echo "==> Zipping app for notarization"
/usr/bin/ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> Submitting to Apple notary service (this waits until done)"
xcrun notarytool submit "$ZIP" \
  --keychain-profile "$KEYCHAIN_PROFILE" \
  --wait

echo "==> Stapling ticket to the app"
xcrun stapler staple "$APP"

echo "==> Verifying"
xcrun stapler validate "$APP"
spctl -a -vvv --type execute "$APP"

echo "==> Done. Notarized app: $APP"
echo "    Re-zip for distribution:  ditto -c -k --keepParent \"$APP\" \"$EXPORT_DIR/aero-notarized.zip\""
