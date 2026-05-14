# AI-only Main + JSONL analyzer (Windows PowerShell parity for run_playtest_npc_only_2min_analyze.sh).
# Usage from repo root: powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_playtest_npc_only_2min_analyze.ps1

$ErrorActionPreference = 'Stop'

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

$GodotCandidate = Join-Path $Root 'tools\Godot\Godot_v4.6.1-stable_win64.exe'
if (-not [string]::IsNullOrWhiteSpace($env:GODOT)) {
	$Godot = $env:GODOT.Trim()
}
elseif (Test-Path -LiteralPath $GodotCandidate) {
	$Godot = $GodotCandidate
}
else {
	Write-Error "Godot exe not found. Set GODOT env or install at $GodotCandidate"
	exit 2
}

$env:SKIP_SINGLE_INSTANCE = '1'

$Stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
if ([string]::IsNullOrWhiteSpace($env:OUT_DIR)) {
	$Out = Join-Path $Root "Tests/logs/playtest_npc_only_2min_$Stamp"
}
elseif ([System.IO.Path]::IsPathRooted($env:OUT_DIR)) {
	$Out = $env:OUT_DIR.Trim()
}
else {
	$Out = Join-Path $Root $env:OUT_DIR.Trim()
}

New-Item -ItemType Directory -Force -Path $Out | Out-Null

$MinEval = $(if ($env:ULTIMATE_MIN_CLAN_BRAIN_EVALS) { $env:ULTIMATE_MIN_CLAN_BRAIN_EVALS } else { '1' })
$MinQuota = $(if ($env:ULTIMATE_MIN_QUOTA_UPDATES) { $env:ULTIMATE_MIN_QUOTA_UPDATES } else { '0' })
$MinGather = $(if ($env:ULTIMATE_NPC_SIM_MIN_GATHER) { $env:ULTIMATE_NPC_SIM_MIN_GATHER } else { '8' })
$MinHWorld = $(if ($env:ULTIMATE_NPC_SIM_MIN_HUNT_WORLD) { $env:ULTIMATE_NPC_SIM_MIN_HUNT_WORLD } else { '1' })
$MinHBrain = $(if ($env:ULTIMATE_NPC_SIM_MIN_HUNT_BRAIN) { $env:ULTIMATE_NPC_SIM_MIN_HUNT_BRAIN } else { '1' })
$MinGrowUniq = $(if ($env:ULTIMATE_NPC_SIM_MIN_GROWTH_UNIQUE) { $env:ULTIMATE_NPC_SIM_MIN_GROWTH_UNIQUE } else { '1' })
$MinNpcSess = $(if ($env:MIN_NPC_SESSION_SEC_FOR_ANALYZE) { $env:MIN_NPC_SESSION_SEC_FOR_ANALYZE } else { '90' })

$PlayUser = @('--npc-only-world', '--playtest-2min', '--playtest-capture', '--playtest-log-dir', $Out)
$SeedEnv = [Environment]::GetEnvironmentVariable('PLAYTEST_WORLD_SEED', 'Process')
if ([string]::IsNullOrWhiteSpace($SeedEnv)) {
	$SeedRaw = '88442201'
} else {
	$SeedRaw = $SeedEnv.Trim()
}
if ($SeedRaw -ne 'random') {
	$PlayUser += @('--playtest-world-seed', $SeedRaw)
}

Write-Host ">>> NPC-only world: playtest 2min + capture -> $Out"

$CombinedLog = Join-Path $Out 'godot.log'
$ErrLog = Join-Path $Out 'godot_err.log'

$p = Start-Process -FilePath $Godot `
	-ArgumentList @('--path', $Root, '--headless', '--') + $PlayUser `
	-NoNewWindow -PassThru -Wait -RedirectStandardOutput $CombinedLog -RedirectStandardError $ErrLog
$ExitCode = $p.ExitCode
Add-Content -Path $CombinedLog -Value "`nEXIT:$ExitCode"

if (-not ([string]::IsNullOrWhiteSpace((Get-Content -Raw $ErrLog)))) {
	Get-Content $ErrLog | Add-Content $CombinedLog
}

if ($ExitCode -ne 0) {
	Write-Error "Godot exited $ExitCode"
	exit $ExitCode
}

Push-Location $Root
try {
	git rev-parse HEAD 2>$null | Out-File (Join-Path $Out 'commit.txt') -Encoding utf8
}
catch {}
Pop-Location

$Jsonl = Join-Path $Out 'playtest_session.jsonl'
if (-not (Test-Path -LiteralPath $Jsonl)) {
	Write-Error "Missing playtest_session.jsonl"
	exit 1
}

$AnalyzeScript = Join-Path $Root 'scripts/logging/analyze_playtest.py'
$AnFlags = @(
	'--strict-clanbrain', '--min-clanbrain-eval-events', $MinEval
	'--strict-npc-sim', '--require-npc-only-session'
	'--min-npc-gather-fsm', $MinGather
	'--min-npc-hunt-world', $MinHWorld
	'--min-npc-hunt-brain', $MinHBrain
	'--min-npc-growth-unique', $MinGrowUniq
	'--min-npc-session-sec', $MinNpcSess
)
if (($MinQuota -match '^[0-9]+$') -and ([int]$MinQuota -gt 0)) {
	$AnFlags += @('--min-clanbrain-quota-updates', $MinQuota)
}
if (-not [string]::IsNullOrWhiteSpace($env:ANALYZER_EXTRA_ARGS)) {
	$tokens = $env:ANALYZER_EXTRA_ARGS.Trim() -split '\s+' | Where-Object { $_ -ne '' }
	$AnFlags += $tokens
}
$AnFlags += @($Jsonl)

Write-Host ">>> python3 $AnalyzeScript $($AnFlags -join ' ')"
& python3 $AnalyzeScript @AnFlags
$Ac = $LASTEXITCODE
Write-Host "Artifacts: $Out"
exit $Ac
