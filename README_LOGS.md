# How to Get Logs

## Quick Method (Recommended)
1. Run the game in Godot editor
2. Open the **Output** panel at the bottom
3. Copy all text (Cmd+A, then Cmd+C)
4. Paste it here

## Automatic Log Capture
Run this command in terminal:
```bash
./run_with_logs.sh
```

This will:
- Start the game
- Save all logs to a file like `game_logs_20240101_120000.txt`
- Show logs in terminal in real-time

After you close the game, the log file will be in the project folder.

## Or run directly:
```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . 2>&1 | tee game_logs.txt
```

