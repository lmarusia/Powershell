# File Integrity Monitoring Tool
# Monitors specified directory for file changes by comparing SHA256 hashes

# Configuration
$monitorPath = "C:\Windows\System32" # Directory to monitor
$baselineFile = "C:\Baselines\System32_Hashes.csv" # Baseline storage location
$logFile = "C:\Logs\FileIntegrity_Log.txt" # Log file location
$checkInterval = 3600 # Check interval in seconds (e.g., 1 hour)

# Ensure directories exist
$baselineDir = Split-Path $baselineFile -Parent
$logDir = Split-Path $logFile -Parent
if (-not (Test-Path $baselineDir)) { New-Item -ItemType Directory -Path $baselineDir -Force }
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force }

# Function to write to log
function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
}

# Function to create baseline
function New-Baseline {
    try {
        Write-Log "Creating new baseline for $monitorPath"
        $files = Get-ChildItem -Path $monitorPath -File -Recurse -ErrorAction Stop
        $hashes = foreach ($file in $files) {
            $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256 -ErrorAction Stop
            [PSCustomObject]@{
                Path = $file.FullName
                Hash = $hash.Hash
                LastWriteTime = $file.LastWriteTime
            }
        }
        $hashes | Export-Csv -Path $baselineFile -NoTypeInformation -ErrorAction Stop
        Write-Log "Baseline created successfully with $($hashes.Count) files"
    } catch {
        Write-Log "Error creating baseline: $($_.Exception.Message)"
    }
}

# Function to check for changes
function Test-Integrity {
    try {
        Write-Log "Starting integrity check"
        if (-not (Test-Path $baselineFile)) {
            Write-Log "Baseline file not found. Creating new baseline."
            New-Baseline
            return
        }

        # Load baseline
        $baseline = Import-Csv -Path $baselineFile
        $currentFiles = Get-ChildItem -Path $monitorPath -File -Recurse -ErrorAction Stop
        $currentHashes = @{}

        # Calculate current hashes
        foreach ($file in $currentFiles) {
            $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256 -ErrorAction Stop
            $currentHashes[$file.FullName] = [PSCustomObject]@{
                Path = $file.FullName
                Hash = $hash.Hash
                LastWriteTime = $file.LastWriteTime
            }
        }

        # Compare baseline with current state
        $changes = @()
        foreach ($base in $baseline) {
            if (-not $currentHashes.ContainsKey($base.Path)) {
                $changes += "Deleted: $($base.Path)"
            } elseif ($currentHashes[$base.Path].Hash -ne $base.Hash) {
                $changes += "Modified: $($base.Path)"
            }
        }

        foreach ($current in $currentHashes.Keys) {
            if (-not ($baseline.Path -contains $current)) {
                $changes += "Added: $current"
            }
        }

        # Log results
        if ($changes.Count -eq 0) {
            Write-Log "No changes detected"
        } else {
            foreach ($change in $changes) {
                Write-Log $change
            }
            Write-Host "Changes detected. Check log at $logFile"
        }
    } catch {
        Write-Log "Error during integrity check: $($_.Exception.Message)"
    }
}

# Main script logic
Write-Log "File Integrity Monitoring Tool started"

# Check if baseline exists; if not, create one
if (-not (Test-Path $baselineFile)) {
    Write-Log "No baseline found. Creating initial baseline."
    New-Baseline
}

# Run continuous monitoring
while ($true) {
    Test-Integrity
    Start-Sleep -Seconds $checkInterval
}