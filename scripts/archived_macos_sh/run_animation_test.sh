#!/bin/bash

# Quick script to run the animation test scene
# This temporarily changes the main scene to AnimationTest.tscn

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Backup current main scene
if grep -q 'run/main_scene=' project.godot; then
    CURRENT_SCENE=$(grep 'run/main_scene=' project.godot | cut -d'=' -f2)
    echo "📝 Current main scene: $CURRENT_SCENE"
else
    CURRENT_SCENE=""
fi

# Set animation test as main scene
echo "🎬 Setting AnimationTest as main scene..."
sed -i.backup 's|run/main_scene=.*|run/main_scene="res://scenes/AnimationTest.tscn"|' project.godot

# Find Godot executable
GODOT_PATH=""
if [ -f "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT_PATH="/Applications/Godot.app/Contents/MacOS/Godot"
elif [ -f "$HOME/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT_PATH="$HOME/Applications/Godot.app/Contents/MacOS/Godot"
elif command -v godot &> /dev/null; then
    GODOT_PATH="godot"
else
    echo "❌ Godot not found. Please install Godot or set GODOT_PATH"
    exit 1
fi

echo "🚀 Running animation test..."
echo "   (Animation will auto-play when scene loads)"
echo ""

# Run Godot
"$GODOT_PATH" --path . 2>&1

# Restore original main scene
if [ -n "$CURRENT_SCENE" ]; then
    echo ""
    echo "🔄 Restoring original main scene..."
    sed -i.backup "s|run/main_scene=.*|run/main_scene=$CURRENT_SCENE|" project.godot
    rm -f project.godot.backup
    echo "✅ Restored: $CURRENT_SCENE"
else
    # Restore from backup
    if [ -f project.godot.backup ]; then
        mv project.godot.backup project.godot
        echo "✅ Restored project.godot from backup"
    fi
fi
