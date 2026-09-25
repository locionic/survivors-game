#!/usr/bin/env bash
set -e

PROJECT_DIR="/home/renovibe79/survivors-game"
BUILD_DIR="$PROJECT_DIR/build/web"
GODOT_BIN="$HOME/.local/bin/godot"

mkdir -p "$BUILD_DIR"

echo "=== Exporting SurvivorQuest for Web (CrazyGames / itch.io) ==="

TEMPLATES_DIR="$HOME/.local/share/godot/export_templates/4.3.stable"

if [ ! -f "$TEMPLATES_DIR/web_nothreads.zip" ] && [ ! -f "$TEMPLATES_DIR/web_dlink_nothreads.zip" ]; then
    echo ""
    echo "Notice: Godot export templates not yet detected."
    echo "You can install them directly inside Godot editor:"
    echo "  1. Launch: ~/.local/bin/godot --editor --path /home/renovibe79/survivors-game"
    echo "  2. Go to: Editor -> Manage Export Templates -> Download and Install"
    echo ""
    echo "Or to download them via terminal (~800MB):"
    echo "  mkdir -p /tmp/templates && curl -L -o /tmp/templates/templates.tpz https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz"
    echo "  unzip -q /tmp/templates/templates.tpz -d /tmp/templates/"
    echo "  mkdir -p $TEMPLATES_DIR && cp -r /tmp/templates/templates/* $TEMPLATES_DIR/"
    echo "  rm -rf /tmp/templates"
    echo ""
fi

# Attempt export
if "$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-release "Web" "$BUILD_DIR/index.html"; then
    echo "Export succeeded! Web files located at: $BUILD_DIR"
    python3 -c '
import zipfile, os
build_dir = "/home/renovibe79/survivors-game/build/web"
zip_path = "/home/renovibe79/survivors-game/build/survivorquest_web.zip"
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(build_dir):
        for f in files:
            full_p = os.path.join(root, f)
            zf.write(full_p, os.path.relpath(full_p, build_dir))
'
    echo "Created upload package: $PROJECT_DIR/build/survivorquest_web.zip"
    echo "Ready to upload to itch.io or CrazyGames!"
else
    echo "Export exited. Ensure export templates are installed."
fi
