# Run the Stone Age Clans Discord lore bot (devblog + bible Q&A).
# Double-click or: powershell -File tools/run_lore_bot.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$token = $env:DISCORD_LORE_BOT_TOKEN
if (-not $token) { $token = $env:DISCORD_BOT_TOKEN }

if (-not $token) {
    Write-Host ""
    Write-Host "Missing bot token." -ForegroundColor Red
    Write-Host "Follow tools/DISCORD_BOT_SETUP.md (about 3 minutes), then run this again."
    Write-Host ""
    exit 1
}

Write-Host "Installing discord.py if needed..."
python -m pip install -q -r tools/requirements-discord-bot.txt

Write-Host "Starting lore bot (Ctrl+C to stop)..."
$env:DISCORD_LORE_BOT_TOKEN = $token
python tools/discord_lore_bot.py
