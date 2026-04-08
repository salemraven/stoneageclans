# Headless party formation test — same scene as agro combat test (2 clans, NPC-led parties).
# Expect JSONL events: party_formation_tick, herd_fsm_transition (party), combat_started, etc.
# Usage: .\Tests\run_party_test.ps1  (requires Godot in PATH or set $env:GODOT)
# Prerequisite: scripts/config/debug_config.gd — allow_agro_combat_test_from_cli = true

$ErrorActionPreference = "Stop"
$godot = if ($env:GODOT) { $env:GODOT } else { "godot" }
$projRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$logDir = Join-Path $PSScriptRoot "party_test_logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

& $godot --headless --path $projRoot `
  -- --playtest-capture --party-test `
  --playtest-log-dir $logDir

Write-Host "Log dir: $logDir"
