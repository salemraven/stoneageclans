# Start web card tuner locally on Windows (no public tunnel).
$ErrorActionPreference = "Stop"
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Port = if ($env:CARD_TUNER_PORT) { $env:CARD_TUNER_PORT } else { 8765 }
Write-Host "Starting card tuner on http://localhost:$Port/"
python "$Root\tools\card_tuner_web\server.py"
