# Configuration
# $logPath = Join-Path -Path $env:USERPROFILE -ChildPath "BinSweepLogs"
$logPath = "C:\BinSweepLogs" # Set log path
$cutoffDate = (Get-Date).AddMonths(-1) # Set cutoff date (1 month ago)
$maxLogFilesToKeep = 7  # Keep only 1 week of logs
$logFile = Join-Path -Path $logPath -ChildPath "BinSweepCleanup_$(Get-Date -Format 'yyyy-MM-dd').log"
$tempFolder = Join-Path $env:TEMP "TempRecycleBin"

# Create log directory if needed
if (-not (Test-Path -Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
}

# Clean up old log files
Get-ChildItem -Path $logPath -Filter "BinSweepCleanup_*.log" |
    Sort-Object LastWriteTime -Descending | 
    Select-Object -Skip $maxLogFilesToKeep | 
    Remove-Item -Force | Out-Null

# Function to write to log file
function Write-Log {
    param ([string]$Message)
    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timeStamp] $Message" | Out-Null
}

# Force run as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "Script is not running with administrative privileges"
}

# Use explicit path to user's recycle bin instead of COM object
$username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[1]
Write-Log "Running as user: $username"

# Start the process
Write-Log "Starting automated recycle bin cleanup (items older than 1 month)"

try {
    # Create a temporary folder to restore items to
    if (Test-Path $tempFolder) { Remove-Item $tempFolder -Recurse -Force | Out-Null }
    New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null
    
    # Use the built-in recycle bin COM objects
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.Namespace(0xA)  # 0xA is the Recycle Bin
    
    # Get all items
    $items = @($recycleBin.Items())
    $totalItems = $items.Count
    Write-Log "Found $totalItems items in Recycle Bin"

    Write-Log "Cutoff date: $cutoffDate"
    
    # Prep for silent operation
    $quietOption = New-Object -ComObject Shell.Application
    $deleteCount = 0
    $errorCount = 0
    
    # Process each item
    foreach ($item in $items) {
        try {
            # Get deletion date
            $dateString = $recycleBin.GetDetailsOf($item, 2) -replace '[^\p{L}\p{N}/.: ]', ''
            
            # Try to parse the date with current culture
            try {
                $deletedDate = [DateTime]::Parse($dateString, [System.Globalization.CultureInfo]::CurrentCulture)
                
                # If older than cutoff, delete permanently (using file system operations)
                if ($deletedDate -lt $cutoffDate) {
                    # Restore to temp folder first - suppressing output with null
                    $null = $quietOption.Namespace($tempFolder).MoveHere($item, 16) # 16 = silent
                    
                    # Get path to restored file
                    $restoredPath = Join-Path $tempFolder $item.Name
                    
                    # Delete permanently - suppressing output
                    if (Test-Path $restoredPath) {
                        Remove-Item -Path $restoredPath -Force -Recurse -ErrorAction Stop | Out-Null
                        $deleteCount++
                    }
                }
            }
            catch {
                # Fallback to checking file metadata
                try {
                    if (Test-Path $item.Path) {
                        $fileObj = Get-Item -Path $item.Path -Force -ErrorAction Stop
                        
                        if ($fileObj.LastWriteTime -lt $cutoffDate) {
                            # Restore to temp folder - suppressing output
                            $null = $quietOption.Namespace($tempFolder).MoveHere($item, 16)
                            
                            # Get path to restored file
                            $restoredPath = Join-Path $tempFolder $item.Name
                            
                            # Delete permanently - suppressing output
                            if (Test-Path $restoredPath) {
                                Remove-Item -Path $restoredPath -Force -Recurse -ErrorAction Stop | Out-Null
                                $deleteCount++
                            }
                        }
                    }
                }
                catch {
                    $errorCount++
                }
            }
        }
        catch {
            $errorCount++
        }
    }
    
    # Log results
    Write-Log "Completed: $deleteCount items deleted, $errorCount errors"
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
}
finally {
    # Clean up the temp folder - suppressing output
    if (Test-Path $tempFolder) {
        Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
    
    # Release COM objects
    try {
        if ($null -ne $recycleBin) { 
            $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($recycleBin)
        }
        if ($null -ne $shell) { 
            $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
        }
        if ($null -ne $quietOption) { 
            $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($quietOption)
        }
    } catch {}
    
    [System.GC]::Collect() | Out-Null
    [System.GC]::WaitForPendingFinalizers() | Out-Null
}
