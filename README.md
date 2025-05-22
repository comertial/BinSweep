# BinSweep 🧹

**BinSweep** is an automated PowerShell utility for Windows that keeps your Recycle Bin tidy by removing items deleted more than 30 days ago. It helps maintain your system’s cleanliness and reclaim disk space — all with minimal effort.

---

## Features ✨

- **Selective Cleaning:** Only files older than 30 days are removed, preserving recent deletions.
- **Comprehensive Logging:** Activity logs for every operation, stored for up to 7 days.
- **Self-Maintenance:** Automatically manages and cleans up old log files.
- **Safe & Reliable:** Temporary folder usage for fail-safe deletions and robust error handling.
- **Efficient:** Designed for low resource usage and minimal disruption.

---

## Requirements 🖥️

- Windows OS
- PowerShell 3.0 or higher
- Administrative privileges

---

## Installation 🚀

### Automatic Installation _(Recommended)_

1. Download `BinSweep.ps1` and `installBinSweep.ps1`.
2. Open PowerShell as **Administrator**.
3. Navigate to the download folder.
4. Run:
    ```powershell
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    .\installBinSweep.ps1
    ```
   - The installer copies BinSweep to Program Files, sets up a daily scheduled task (3:00 PM by default), and configures reliability settings.

#### Alternate Method

If needed, use this to install directly:
```powershell
powershell -ExecutionPolicy Bypass -File "path\to\installBinSweep.ps1"
```

#### Custom Installation

Specify install options if desired:
```powershell
.\installBinSweep.ps1 -InstallLocation "C:\Custom\Path" -SourceScript "C:\Path\To\BinSweep.ps1"
```

### Manual Setup

1. Save `BinSweep.ps1` to your chosen folder.
2. Allow PowerShell script execution as needed.
3. In Task Scheduler:
   - Create a new task named **BinSweep**
   - Schedule it for your preferred time (default: daily, 3:00 PM)
   - **Program/script:**  
     `PowerShell.exe`
   - **Add arguments:**
     ```
     -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Path\To\BinSweep.ps1"
     ```
   - (Recommended) Under task properties:
      - ✔️ "Run with highest privileges"
      - (Optional) On failure, retry every 5 minutes, up to 3 attempts
      - ✔️ "Run task as soon as possible after a scheduled start is missed"

---

## Usage ▶️

**To run manually in PowerShell (as admin):**
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Path\To\BinSweep.ps1"
```

**Or, to run/verify via Task Scheduler:**
- Open Task Scheduler, select & run **BinSweep**
- Or in PowerShell:
  ```powershell
  Start-ScheduledTask -TaskName 'BinSweep'
  ```

---

## Configuration ⚙️

At the top of `BinSweep.ps1`, tweak these as needed:
- `$logPath`: Log file location (default: `"C:\BinSweepLogs"`)
- `$maxLogFilesToKeep`: Log retention (default: `7`)
- `$cutoffDate`: Deletion threshold (default: 30 days)

---

## How BinSweep Works 🗑️

1. Ensures log directory exists.
2. Cleans old logs.
3. Scans the Recycle Bin.
4. Moves & deletes files older than `$cutoffDate`.
5. Logs every action and cleans up temp files.

---

## Logs 📄

- Named `BinSweepCleanup_yyyy-MM-dd.log`
- Timestamped, detailed entries
- Old logs removed automatically

---

## Troubleshooting 🛠️

- Check log files for errors
- Confirm script has admin rights
- Ensure Recycle Bin isn’t being used by another app

---

## Uninstallation ❌

1. Delete the **BinSweep** task from Task Scheduler.
2. Remove BinSweep files from the install location.
3. (Optional) Delete the log directory.

---

## License 📜

Licensed under the [MIT License](LICENSE).

---

## Contributing 🤝

Have suggestions or improvements? Open a pull request or issue to discuss your ideas!