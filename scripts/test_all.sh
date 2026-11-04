#!/usr/bin/env bash
# ==============================================================================
# Comprehensive Local Test Runner
# Executes Contract Verification, Backend Pytest, and Frontend Flutter Tests
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== [1/3] Verifying OpenAPI Contracts ==="
"${ROOT_DIR}/backend/.venv/bin/python" "${ROOT_DIR}/contracts/verify_contracts.py"

echo ""
echo "=== [2/3] Running Backend Tests (pytest) ==="
cd "${ROOT_DIR}/backend"
"${ROOT_DIR}/backend/.venv/bin/pytest" -v

echo ""
echo "=== [3/3] Running Frontend Tests (flutter test) ==="
cd "${ROOT_DIR}/frontend"
flutter test

echo ""
echo "=========================================================="
echo "🎉 ALL INTEGRATION AND UNIT TESTS PASSED SUCCESSFULLY!"
echo "=========================================================="
