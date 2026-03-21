#!/bin/bash
# Occupation Diagnostic Test Runner
# Captures building occupation flow: land claim, Farm, Dairy, women, animals
#
# Usage:
#   ./Tests/run_occupation_test.sh
#   ./Tests/run_occupation_test.sh 2>&1 | tee Tests/occupation_console.log
#
# Logs written to: Tests/occupation_diag_<timestamp>.log

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Occupation Diagnostic Test ==="
echo "Project: $PROJECT_ROOT"
echo ""
echo "Test steps:"
echo "  1. Place a Land Claim (from hotbar) and name your clan"
echo "  2. Open land claim inventory, place Farm and Dairy"
echo "  3. Herd sheep, goats, and women into the land claim"
echo "  4. (Optional) Try dragging an animal from a building slot onto the map"
echo ""
echo "Diagnostic log: Tests/occupation_diag_*.log"
echo ""

cd "$PROJECT_ROOT"
godot --path . --occupation-diag "$@"
