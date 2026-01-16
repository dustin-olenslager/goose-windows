# Setup Auto-Sync Task for Goose Windows
# This creates a Windows Task Scheduler task to automatically sync with upstream

param(
    [int]$IntervalHours = 4,
    [switch]$Remove
)

$TaskName = "GooseWindowsSync"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$SyncScript = "$RepoRoot\scripts\windows\sync-and-build.ps1"

if ($Remove) {
    Write-Host "Removing scheduled task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "Task removed." -ForegroundColor Green
    exit 0
}

Write-Host "Setting up automatic sync every $IntervalHours hours..." -ForegroundColor Cyan

# Create the action
$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$SyncScript`" -Silent" `
    -WorkingDirectory $RepoRoot

# Create trigger (every N hours)
$Trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Hours $IntervalHours) `
    -RepetitionDuration (New-TimeSpan -Days 365)

# Create settings
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable

# Register the task
$Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

# Remove existing task if present
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

# Create new task
Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Principal $Principal `
    -Description "Automatically sync Goose Windows fork with upstream block/goose" | Out-Null

Write-Host ""
Write-Host "Scheduled task created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Task Details:" -ForegroundColor Cyan
Write-Host "  Name: $TaskName"
Write-Host "  Interval: Every $IntervalHours hours"
Write-Host "  Script: $SyncScript"
Write-Host ""
Write-Host "To remove: .\setup-auto-sync.ps1 -Remove" -ForegroundColor Yellow
Write-Host "To change interval: .\setup-auto-sync.ps1 -IntervalHours 2" -ForegroundColor Yellow
