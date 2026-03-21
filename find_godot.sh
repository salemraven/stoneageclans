#!/bin/bash
# Helper script to find Godot installation on macOS

echo "Searching for Godot installation..."
echo ""

# Check common locations
PATHS=(
  "$HOME/Applications/Godot.app/Contents/MacOS/Godot"
  "/Applications/Godot.app/Contents/MacOS/Godot"
  "/opt/homebrew/bin/godot"
  "/usr/local/bin/godot"
)

FOUND=false
for path in "${PATHS[@]}"; do
  if [ -f "$path" ] && [ -x "$path" ]; then
    echo "✓ Found: $path"
    FOUND=true
    echo ""
    echo "Add this to .vscode/settings.json:"
    echo '  "godot_tools.editor_path": "'"$path"'",'
    break
  fi
done

if [ "$FOUND" = false ]; then
  echo "✗ Godot not found in standard locations"
  echo ""
  echo "To fix this:"
  echo "1. Download Godot from https://godotengine.org/download"
  echo "2. Drag Godot.app to /Applications or ~/Applications"
  echo "3. Or set the path manually in .vscode/settings.json:"
  echo '   "godot_tools.editor_path": "/path/to/Godot.app/Contents/MacOS/Godot",'
fi

