#!/usr/bin/env bash
# ==============================================================================
# Full Stack Build Orchestration Script
# Verifies contracts, validates backend, and builds the Flutter production bundle
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== [1/3] Validating OpenAPI Contract Alignment ==="
"${ROOT_DIR}/backend/.venv/bin/python" "${ROOT_DIR}/contracts/verify_contracts.py"

echo ""
echo "=== [2/3] Verifying Backend Application Integrity ==="
cd "${ROOT_DIR}/backend"
"${ROOT_DIR}/backend/.venv/bin/pytest" -q

echo ""
echo "=== [3/3] Building Flutter Web Production Release ==="
cd "${ROOT_DIR}/frontend"
flutter pub get
flutter analyze --fatal-infos
flutter build web --release --no-tree-shake-icons

echo ""
echo "=========================================================="
echo "🚀 PRODUCTION BUILD READY!"
echo "Flutter web bundle located at: ${ROOT_DIR}/frontend/build/web"
echo "=========================================================="
