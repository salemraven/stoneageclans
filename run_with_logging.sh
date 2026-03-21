#!/bin/bash
# Run Godot with logging to capture combat/animation debug output

# Try common Godot locations (check found location first)
GODOT_PATHS=(
    "/Applications/Godot.app/Contents/MacOS/Godot"
    "/Applications/Godot_mono.app/Contents/MacOS/Godot"
    "$HOME/Applications/Godot.app/Contents/MacOS/Godot"
    "$HOME/Applications/Godot_mono.app/Contents/MacOS/Godot"
    "/usr/local/bin/godot"
    "/opt/homebrew/bin/godot"
    "$GODOT_CMD"  # Use environment variable if set
)

GODOT_CMD=""
for path in "${GODOT_PATHS[@]}"; do
    if [ -f "$path" ]; then
        GODOT_CMD="$path"
        echo "✅ Found Godot at: $path"
        break
    fi
done

if [ -z "$GODOT_CMD" ]; then
    echo "❌ Godot not found. Please install Godot or set GODOT_CMD environment variable"
    echo "   Example: export GODOT_CMD=\"/path/to/Godot.app/Contents/MacOS/Godot\""
    exit 1
fi

# Create logs directory
mkdir -p logs

# Run with logging
LOG_FILE="logs/combat_$(date +%Y%m%d_%H%M%S).log"
echo "📝 Logging to: $LOG_FILE"
echo "🎮 Starting Godot with combat logging..."
echo "   Press Ctrl+C to stop"
echo ""

# Run Godot and capture all output
"$GODOT_CMD" --path . --verbose 2>&1 | tee "$LOG_FILE"

echo ""
echo "✅ Log saved to: $LOG_FILE"
