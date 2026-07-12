#!/bin/bash
# Run Flutter tests with compile-time credentials
set -euo pipefail
cd "$(dirname "$0")/.."
echo "=== Running Azdal tests (credentials from .env) ==="
flutter test --dart-define-from-file=.env "$@"
