#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "=== BLEP MAP iOS -> unsigned IPA for AltStore ==="
rm -rf build Payload BLEP_MAP_ALTSTORE.ipa

xcodebuild \
  -project BLEPMap.xcodeproj \
  -scheme BLEPMap \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP_PATH="build/Build/Products/Release-iphoneos/BLEPMap.app"
if [ ! -d "$APP_PATH" ]; then
  echo "ERROR: .app was not produced."
  exit 1
fi

mkdir Payload
cp -R "$APP_PATH" Payload/BLEPMap.app
/usr/bin/zip -qry BLEP_MAP_ALTSTORE.ipa Payload

echo
echo "DONE: BLEP_MAP_ALTSTORE.ipa"
open .
