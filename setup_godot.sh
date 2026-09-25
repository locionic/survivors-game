#!/usr/bin/env bash
set -e

GODOT_DIR="$HOME/.local/bin"
mkdir -p "$GODOT_DIR"

if ! command -v godot &> /dev/null; then
    echo "Downloading Godot 4.3 Stable..."
    TMP_ZIP="/tmp/godot_linux.zip"
    curl -L -o "$TMP_ZIP" "https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip"
    unzip -o "$TMP_ZIP" -d "$GODOT_DIR"
    rm -f "$TMP_ZIP"
    
    GODOT_BIN=$(find "$GODOT_DIR" -name "Godot_v4.3*" -type f | head -n 1)
    chmod +x "$GODOT_BIN"
    ln -sf "$GODOT_BIN" "$GODOT_DIR/godot"
    echo "Godot 4.3 installed to $GODOT_DIR/godot"
fi

echo "To launch the game editor, run:"
echo "  ~/.local/bin/godot --editor --path /home/renovibe79/survivors-game"
echo ""
echo "To run the game directly:"
echo "  ~/.local/bin/godot --path /home/renovibe79/survivors-game"
