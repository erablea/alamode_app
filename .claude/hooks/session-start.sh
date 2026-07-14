#!/bin/bash
set -euo pipefail

# Claude Code on the web以外(ローカル環境等)では何もしない
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

FLUTTER_DIR="/opt/flutter"
FLUTTER_VERSION="3.44.6"
FLUTTER_ARCHIVE_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "Flutter SDK (${FLUTTER_VERSION}) をインストールしています..."
  curl -fsSL -o /tmp/flutter.tar.xz "$FLUTTER_ARCHIVE_URL"
  mkdir -p "$FLUTTER_DIR"
  tar xf /tmp/flutter.tar.xz -C /opt
  rm -f /tmp/flutter.tar.xz
fi

if ! git config --global --get-all safe.directory 2>/dev/null | grep -qx "$FLUTTER_DIR"; then
  git config --global --add safe.directory "$FLUTTER_DIR"
fi

ln -sf "$FLUTTER_DIR/bin/flutter" /usr/local/bin/flutter
ln -sf "$FLUTTER_DIR/bin/dart" /usr/local/bin/dart

echo "export PATH=\"$FLUTTER_DIR/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"

cd "$CLAUDE_PROJECT_DIR"
flutter pub get
