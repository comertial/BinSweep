<#
.SYNOPSIS
    Installs BinSweep and creates a scheduled task to run it daily.
.DESCRIPTION
    This script:
    1. Copies the BinSweep.ps1 script to a permanent location
    2. Creates a scheduled task that runs BinSweep daily
    3. Configures the task with appropriate settings for reliability
.NOTES
    Author: BinSweep Team
    Website: https://github.com/comertial/BinSweep
#>

param(
    [string]$InstallLocation = "$env:ProgramFiles\BinSweep",
    [string]$SourceScript = ".\BinSweep.ps1"
)

# Ensure we're running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script needs to be run as Administrator. Please restart with elevated privileges."
    exit 1
}

# Check if source script exists
if (-not (Test-Path $SourceScript)) {
    Write-Error "Could not find BinSweep.ps1 at $SourceScript. Please make sure the script is in the current directory or provide the correct path."
    exit 1
}

# Create installation directory if it doesn't exist
if (-not (Test-Path $InstallLocation)) {
    Write-Host "Creating installation directory at $InstallLocation..."
    New-Item -Path $InstallLocation -ItemType Directory -Force | Out-Null
}

# Copy script to installation location
$targetPath = Join-Path -Path $InstallLocation -ChildPath "BinSweep.ps1"
Write-Host "Installing BinSweep script to $targetPath..."
Copy-Item -Path $SourceScript -Destination $targetPath -Force

# Create scheduled task
$taskName = "BinSweep"
$taskDescription = "Deletes old items from the Recycle Bin. For more information follow this link: https://github.com/comertial/BinSweep"

Write-Host "Creating scheduled task '$taskName'..."

# Create action
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$targetPath`""

# Create trigger (daily at 3:00 PM)
$trigger = New-ScheduledTaskTrigger -Daily -At "15:00"

# Configure settings
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 5) `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2)

# Get the current username for task registration
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Configure principal (run with highest privileges as current user)
$principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Highest

# Register the task
Register-ScheduledTask -TaskName $taskName `
    -Description $taskDescription `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Force

Write-Host "BinSweep has been successfully installed and scheduled." -ForegroundColor Green
Write-Host "Installation location: $targetPath"
Write-Host "Task schedule: Daily at 3:00 PM"
Write-Host "Task runs as: $currentUser"
Write-Host "You can manually run the task from Task Scheduler or by running: Start-ScheduledTask -TaskName 'BinSweep'"
