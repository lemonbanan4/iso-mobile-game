#!/usr/bin/env bash
# Netlify build helper — installs Flutter SDK then produces release web bundle.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.35.0}"
INSTALL_DIR="${HOME}/flutter"

if [[ ! -x "${INSTALL_DIR}/bin/flutter" ]]; then
  echo "==> Installing Flutter ${FLUTTER_VERSION}"
  git clone https://github.com/flutter/flutter.git -b "stable" --depth 1 "${INSTALL_DIR}"
fi

export PATH="${INSTALL_DIR}/bin:${PATH}"
flutter --version
flutter config --no-analytics
flutter precache --web

cd "$(dirname "$0")/../frontend"
flutter pub get
flutter analyze
flutter test
flutter build web --release --no-tree-shake-icons --base-href /
