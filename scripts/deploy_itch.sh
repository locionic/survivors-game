#!/usr/bin/env bash
set -euo pipefail

# Deploy script for pushing latest Godot Web export to itch.io (locionic/survivorquest:html5)
TARGET="${ITCH_TARGET:-locionic/survivorquest:html5}"
BUTLER_BIN="${BUTLER_BIN:-/home/codespace/.local/bin/butler}"
BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/build/web"

if [ -z "${BUTLER_API_KEY:-}" ]; then
  if [ -n "${1:-}" ]; then
    export BUTLER_API_KEY="$1"
  else
    echo "Error: BUTLER_API_KEY environment variable or argument required."
    echo "Usage: BUTLER_API_KEY=xxx ./scripts/deploy_itch.sh [or ./scripts/deploy_itch.sh <key>]"
    exit 1
  fi
fi

if ! command -v "$BUTLER_BIN" &>/dev/null && [ ! -f "$BUTLER_BIN" ]; then
  echo "Installing butler..."
  curl -sL https://github.com/itchio/butler/releases/download/v15.32.0/butler-linux-amd64.zip -o /tmp/butler.zip
  unzip -qo /tmp/butler.zip -d /tmp/butler_unzip
  mkdir -p "$(dirname "$BUTLER_BIN")"
  mv /tmp/butler_unzip/linux-amd64/* "$(dirname "$BUTLER_BIN")/"
  chmod +x "$BUTLER_BIN"
fi

echo "Packaging latest game assets and scripts into $BUILD_DIR/index.pck..."
godot --headless --path "$(dirname "${BASH_SOURCE[0]}")/.." --export-pack "Web" "$BUILD_DIR/index.pck"

GIT_REV="$(git rev-parse --short HEAD 2>/dev/null || echo 'live')"
VERSION="1.6.0-zombie-ui-${GIT_REV}"

echo "Pushing $BUILD_DIR to $TARGET (version: $VERSION)..."
"$BUTLER_BIN" push --userversion "$VERSION" "$BUILD_DIR" "$TARGET"
"$BUTLER_BIN" status "$TARGET"
echo "Successfully deployed to itch.io!"
