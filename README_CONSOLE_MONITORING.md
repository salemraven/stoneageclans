# Console Monitoring Guide

## Quick Start

### Option 1: Run Game with Logging (Recommended)

1. **Open Terminal** in the project directory
2. **Run the game with output redirection:**
   ```bash
   # If Godot is in your PATH:
   godot . > game_console.log 2>&1 &
   
   # Or if using Godot from Applications:
   /Applications/Godot.app/Contents/MacOS/Godot . > game_console.log 2>&1 &
   ```

3. **Monitor the log in real-time:**
   ```bash
   ./monitor_console.sh
   ```
   
   Or manually:
   ```bash
   tail -f game_console.log | grep -E "GATHER|DEPOSIT|WANDER|CLAN_NAME|Missing tool|No gather target"
   ```

### Option 2: Monitor Godot Editor Console

If running from the Godot editor:
1. Open the **Output** panel (bottom of editor)
2. The console output will appear there
3. Look for messages containing:
   - `GATHER CAN_ENTER`
   - `No gather target found`
   - `Missing tool`
   - `placed land claim`
   - `RESOURCE FIND`

### Option 3: View Log File After Running

After running the game, view the log:
```bash
# View filtered output
grep -E "GATHER|DEPOSIT|WANDER|CLAN_NAME|Missing tool|No gather target" game_console.log

# View last 100 lines
tail -100 game_console.log

# View all output
cat game_console.log
```

## What to Look For

### Success Messages:
- `✅ GATHER CAN_ENTER: [NPC] - Has tool (NONE) for [resource], can gather!`
- `✅ RESOURCE FIND: [NPC] - Found X resources in range`
- `✅ GATHER AUTO-DEPOSIT SUCCESS: [NPC] deposited X items`

### Problem Messages:
- `⚠️ GATHER CAN_ENTER: [NPC] - No gather target found` - No resources found
- `❌ GATHER CAN_ENTER: [NPC] - Missing tool! Need AXE/PICK` - NPC needs tools
- `⚠️ RESOURCE FIND: [NPC] - No resources found in 'resources' group!` - Resources not spawning

### Key Information:
- `detection_range=X` - How far NPCs can detect resources
- `total_resources=X` - How many resources exist in the game
- `perception=X` - NPC's perception stat
- `clan='...'` - NPC's clan name (should be set after land claim)

## Stopping the Game

If you started the game in the background:
```bash
# Find the process
ps aux | grep godot

# Kill it
kill $(cat game_pid.txt)  # If using the PID file
# Or
pkill -f godot
```

