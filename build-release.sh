#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_PROPERTIES_FILE="$SCRIPT_DIR/android/key.properties"
BUILD_OUTPUT_FILE="$SCRIPT_DIR/build/app/outputs/flutter-apk/app-release.apk"

if [[ ! -f "$KEY_PROPERTIES_FILE" ]]; then
  echo "Missing android/key.properties."
  echo "Copy android/key.properties.example to android/key.properties and fill in storeFile and keyAlias."
  exit 1
fi

if [[ -z "${SAATENSCHLUESSEL_STORE_PASSWORD:-}" ]]; then
  read -r -s -p "Keystore password: " SAATENSCHLUESSEL_STORE_PASSWORD
  echo
  export SAATENSCHLUESSEL_STORE_PASSWORD
fi

if [[ -z "${SAATENSCHLUESSEL_KEY_PASSWORD:-}" ]]; then
  read -r -s -p "Key password: " SAATENSCHLUESSEL_KEY_PASSWORD
  echo
  export SAATENSCHLUESSEL_KEY_PASSWORD
fi

cd "$SCRIPT_DIR"
flutter build apk --release "$@"

if [[ ! -f "$BUILD_OUTPUT_FILE" ]]; then
  echo "Expected APK was not created: $BUILD_OUTPUT_FILE"
  exit 1
fi

echo "Release APK created:"
echo "  $BUILD_OUTPUT_FILE"
