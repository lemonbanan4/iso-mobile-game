#!/usr/bin/env bash
# ==============================================================================
# Flutter Web production bundle for static hosts (Vercel / Netlify / GH Pages)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
FRONTEND_DIR="${ROOT_DIR}/frontend"

cd "${FRONTEND_DIR}"

echo "==> flutter pub get"
flutter pub get

echo "==> flutter analyze"
flutter analyze

echo "==> flutter test"
flutter test

echo "==> flutter build web --release"
flutter build web --release --no-tree-shake-icons --base-href /

OUT="${FRONTEND_DIR}/build/web"
echo ""
echo "Production web bundle ready:"
echo "  ${OUT}"
echo ""
echo "Serve locally:"
echo "  cd frontend && python3 -m http.server 4173 --directory build/web"
echo ""
echo "Deploy:"
echo "  - Netlify: publish directory frontend/build/web (see netlify.toml)"
echo "  - Vercel:  outputDirectory frontend/build/web (see vercel.json)"
echo "  - GitHub Pages: push to main triggers .github/workflows/deploy-web.yml"
