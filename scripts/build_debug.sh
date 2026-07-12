#!/bin/bash
# Build debug APK with compile-time credentials from .env
# Usage: bash scripts/build_debug.sh [extra flutter args]
set -euo pipefail
cd "$(dirname "$0")/.."
echo "=== Building Azdal debug APK (credentials from .env) ==="
flutter build apk --debug --dart-define-from-file=.env "$@"
echo "=== APK: build/app/outputs/flutter-apk/app-debug.apk ==="
