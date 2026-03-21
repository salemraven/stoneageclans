# Stone Age Clans - Testing Framework

## Overview

This document outlines the two-phase testing strategy for the game:

1. **Phase 1: Comprehensive Debug Testing** - Full logging and monitoring to gather data and identify issues
2. **Phase 2: Performance Testing** - Clean production mode to test actual gameplay without debug overhead

## File Organization

All test-related files are organized in the `Tests/` folder:

- **Test Scripts:** `Tests/TEST1_RUN_COMMAND.sh`, `Tests/TEST1_EXECUTE.sh`
- **Test Logs:** `Tests/test1_*.log`, `Tests/test_output.log`
- **Analysis Reports:** `Tests/TEST1_CAVEMAN_ANALYSIS.md`, `Tests/DEEP_DIVE_ANALYSIS.md`, etc.
- **Test Documentation:** All analysis and findings documents

**Note:** The main `TESTING_FRAMEWORK.md` file remains in the project root for easy access.

---

## Phase 1: Comprehensive Debug Testing

### Objective
Gather comprehensive data about NPC behavior, system performance, world state, and identify crashes/freezes. Use this data to fix issues and optimize performance.

### Debug Framework Components

#### 1. Enhanced Logging System

**MinigameLogger** (already exists, needs enhancement):
- Enable comprehensive logging for all NPC actions
- Log state transitions, priority evaluations, and decision-making
- Track herd mentality calculations, attraction values, and leader switches
- Monitor land claim placement attempts and failures
- Log performance metrics (frame time, memory usage)

**Key Log Categories to Track:**
- NPC State Machine (every state entry/exit)
- FSM Priority Evaluations (which states are being considered)
- Herd Mentality (attraction calculations, leader changes)
- Land Claim Placement (attempts, failures, overlaps)
- Resource Management (spawning, collection, inventory)
- Performance Metrics (delta time, frame drops, memory)
- Error/Warning Tracking (any script errors or warnings)

#### 2. Performance Monitoring

**Metrics to Track:**
- Frame time (delta) - flag when > 16.67ms (60 FPS threshold)
- NPC count and their states
- Memory usage (Object count, memory pools)
- Group node counts (land_claims, npcs, resources)
- FSM evaluation time per NPC
- Logging overhead (time spent in logging functions)

#### 3. Command Line Execution

**Running Godot from Command Line:**
```bash
# Run the project with output to console
godot --path . --verbose

# Or run with output redirected to file
godot --path . --verbose > game_output.log 2>&1

# Run in headless mode (no window) for automated testing
godot --path . --headless --verbose > game_output.log 2>&1
```

**Useful Command Line Options:**
- `--verbose` - More detailed console output
- `--headless` - Run without opening a window (useful for automated tests)
- `--script` - Run a specific script
- `--quit-after` - Quit after X seconds

#### 4. Data Collection Strategy

**What to Monitor:**

1. **NPC Behavior:**
   - How many NPCs are in each state?
   - State transition frequency
   - Priority evaluation results
   - Herd formation and breakup events

2. **World State:**
   - Number of land claims
   - Resource spawn rates
   - Distance between entities
   - Boundary enforcement

3. **Performance:**
   - Frame time spikes
   - Memory leaks (increasing memory over time)
   - Expensive operations (which functions take longest)

4. **Errors/Crashes:**
   - Script errors with stack traces
   - Null reference errors
   - Invalid state transitions
   - Resource loading failures

#### 5. Debug UI (Optional Enhancement)

Add an on-screen debug overlay showing:
- Current FPS
- NPC count by state
- Memory usage
- Active land claims
- Performance warnings

---

## Phase 2: Performance Testing (Clean Mode)

### Objective
Test the game in production-like conditions without debug overhead to get accurate performance metrics and gameplay feel.

### Implementation

**Debug Toggle System:**
- Create a `DebugConfig` autoload singleton (or use existing one)
- Centralized flag to enable/disable all debug features
- All loggers check this flag before doing any work

**What Gets Disabled:**
- All file logging
- All console logging (except critical errors)
- Debug UI overlays
- Performance profiling code
- Verbose state logging
- Detailed error tracking

**What Stays Enabled:**
- Critical error handling (crashes should still be logged)
- Essential game logic validation
- Basic error messages (not full logging)

---

## Unified Test (Clansmen Efficiency)

**Primary goal:** Measure and improve clansmen efficiency and success — active searching for herds, successful herding (NPCs joining clan), gathering, and depositing.

**How to run:** `./Tests/run.sh unified` (default 4 min) or `./Tests/run.sh unified 300`. Output is in `Tests/results/unified_<timestamp>/`.

**How to read results:**
- **unified_report.md** — Efficiency summary first (herding success count, search activity, gathers, deposits, per-minute rates), then pass/fail per system. Use this to see where clansmen are underperforming.
- **unified_result.env** — Machine-readable: `HERD_JOINED_COUNT`, `GATHER_COUNT`, `DEPOSIT_COUNT`, `SEARCH_ACTIVITY_OK`, `EFFICIENCY_PASS`, etc. Exit code 0 = efficiency baseline passed, 1 = failed.

**Pass criteria:** Spawn OK (claims + ClanBrain), at least one gather and one deposit, evidence of search activity (herd_wildnpc). Ideally at least one herding success (NPC joined clan). Red flags: zero gathers/deposits, no search activity, crashes, dangling combat.

---

## Implementation Plan

### Step 1: Create Debug Configuration System

**File: `scripts/debug_config.gd`** (enhance existing or create new)

```gdscript
extends Node

# Centralized debug configuration
# Set via command line or in code

var enable_all_logging: bool = false
var enable_file_logging: bool = false
var enable_console_logging: bool = false
var enable_performance_monitoring: bool = false
var enable_debug_ui: bool = false
var enable_verbose_npc_logging: bool = false

# Command line argument parsing
func _ready() -> void:
	_parse_command_line_args()

func _parse_command_line_args() -> void:
	var args = OS.get_cmdline_args()
	
	# Check for --debug flag
	if "--debug" in args or "--verbose" in args:
		enable_all_logging = true
		enable_file_logging = true
		enable_console_logging = true
		enable_performance_monitoring = true
		enable_verbose_npc_logging = true
		print("Debug mode enabled via command line")
	
	# Check for --log-file flag
	if "--log-file" in args:
		enable_file_logging = true
```

### Step 2: Enhance MinigameLogger

**Modify to respect DebugConfig:**
- Check `DebugConfig.enable_file_logging` before file operations
- Check `DebugConfig.enable_console_logging` before console output
- Early exit if both disabled (already implemented)

### Step 3: Add Performance Monitor

**Create `scripts/debug/performance_monitor.gd`:**
- Track frame times
- Monitor memory usage
- Count nodes in groups
- Log performance spikes

### Step 4: Create Test Runner Script

**File: `scripts/test_runner.gd`:**
- Run automated test scenarios
- Collect metrics over time
- Generate test report
- Can be run from command line

---

## Running Tests

### Phase 1: Debug Testing

**Using Test Scripts (Recommended):**
```bash
# Run Test 1 with automated analysis
cd /Users/macbook/Desktop/stoneageclans
./Tests/TEST1_RUN_COMMAND.sh

# Or use the execute script
./Tests/TEST1_EXECUTE.sh
```

**Manual Execution:**
```bash
# Run with full debug logging
godot --path . --verbose --debug

# Run with output to file (saved in Tests folder)
godot --path . --verbose --debug > Tests/debug_test.log 2>&1

# Run for specific duration (e.g., 60 seconds)
timeout 60 godot --path . --headless --verbose --debug > Tests/debug_test.log 2>&1
```

**Test Output Location:**
- Log files: `Tests/test1_*.log`
- Analysis reports: `Tests/*_ANALYSIS.md`

**What to Look For:**
1. Check console for errors/warnings
2. Review log file for patterns:
   - NPCs stuck in loops
   - Excessive state transitions
   - Memory leaks (growing object counts)
   - Performance issues (frame time spikes)
3. Identify bottlenecks in logs
4. Check for crashes or freezes

### Phase 2: Performance Testing

```bash
# Run in clean mode (no debug flags)
godot --path . --verbose

# Or just run normally
godot --path .
```

**What to Test:**
1. Gameplay feel (responsiveness)
2. Frame rate stability
3. Memory usage over time
4. No crashes or freezes
5. NPC behavior looks correct

---

## Integration with Godot 4.x

### Best Practices

1. **Use Autoload Singletons:**
   - `DebugConfig` - centralized debug settings
   - `MinigameLogger` - already exists
   - `PerformanceMonitor` - new, optional

2. **Conditional Compilation:**
   - Use `#ifdef`-like patterns with boolean flags
   - Check flags at runtime (Godot doesn't have true preprocessor)

3. **Command Line Integration:**
   - Parse `OS.get_cmdline_args()` in `_ready()`
   - Set debug flags based on arguments

4. **Log File Management:**
   - Use `user://` directory for logs (portable, writeable)
   - Rotate log files to prevent huge files
   - Optionally compress old logs

5. **Performance Impact:**
   - Early exits in logging functions (already done)
   - String formatting only when logging enabled
   - Batch logging operations when possible

---

## Data Analysis Workflow

### After Phase 1 Test:

1. **Review Log Files:**
   - Log files are in `Tests/` folder: `Tests/test1_*.log`
   - Search for errors/warnings
   - Look for performance spikes
   - Identify state machine issues
   - Check for memory leaks

2. **Review Analysis Reports:**
   - Check `Tests/TEST1_CAVEMAN_ANALYSIS.md` for test results
   - Review `Tests/DEEP_DIVE_ANALYSIS.md` for detailed findings
   - Check other analysis files in `Tests/` folder for specific issues

2. **Identify Patterns:**
   - Which NPCs are problematic?
   - What states cause issues?
   - When do performance issues occur?

3. **Create Fixes:**
   - Address identified issues
   - Optimize bottlenecks
   - Fix state machine bugs

4. **Repeat:**
   - Run Phase 1 again to verify fixes
   - Compare before/after metrics

### Metrics to Track:

- **NPC State Distribution:** How many in each state?
- **State Transition Frequency:** Are NPCs switching too often?
- **Frame Time:** Average, min, max, spikes
- **Memory:** Initial, peak, final, growth rate
- **Error Rate:** Count of errors per minute
- **Logging Overhead:** Time spent in logging vs game logic

---

## Next Steps

1. ✅ Enhance `DebugConfig` to parse command line args - **DONE**
2. ✅ Verify `MinigameLogger` respects debug flags - **DONE**
3. ✅ Add DebugConfig autoload to project.godot - **DONE**
4. ✅ Organize test files into `Tests/` folder - **DONE**
5. ⬜ Create `PerformanceMonitor` for frame time tracking
6. ⬜ Add performance logging to key systems
7. ⬜ Create test scenarios (e.g., spawn 50 NPCs, let run for 5 minutes)
8. ⬜ Document log analysis procedures
9. ⬜ Create scripts to parse/analyze log files

---

## Notes

- **Logging Overhead:** Even with early exits, function call overhead exists. Consider removing log calls entirely in production builds if needed.

- **File I/O:** File logging can be slow. Consider:
  - Writing to memory buffer, flush periodically
  - Use separate thread for logging (if needed)
  - Limit log file size

- **Console Output:** Printing to console can be slow with many NPCs. Disable in production.

- **Godot Profiler:** Use Godot's built-in profiler (`--profile`) for detailed performance analysis separately from logging.



ok so lets try running test 1 we will make sure the 1 game loads without crashing and freezing 2 caveman npcs are moving around placeing landlcaims and trying to herd NPCs to herd npcs into their landclaim area. 3  herd npcs are in wonder mode until they get herded then go into herd mode 4. caveman npcs are able to steal herded npcs from another caveman npc. reply with an easy to understand report of the results of test 1. what you found and what to fix, and what to change for better performance. 


