# Ensure the script runs with elevated privileges
if (-not [System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) {
    Write-Host "This script requires administrator privileges!" -ForegroundColor Red
    exit
}

# Load PSWindowsUpdate module if not already loaded
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "PSWindowsUpdate module is not installed. Installing..." -ForegroundColor Yellow
    Install-Module -Name PSWindowsUpdate -Force -AllowClobber -Scope CurrentUser
}

Import-Module PSWindowsUpdate

# Check for pending updates
Write-Host "Checking for pending updates..." -ForegroundColor Cyan
$updates = Get-WindowsUpdate -AcceptAll -IgnoreReboot -Verbose

# If updates are found, install them
if ($updates.Count -gt 0) {
    Write-Host "$($updates.Count) updates found. Installing..." -ForegroundColor Cyan

    # Install the updates
    $updates | Install-WindowsUpdate -AcceptAll -AutoReboot -Verbose

    Write-Host "Updates installed successfully." -ForegroundColor Green
} else {
    Write-Host "No updates are pending." -ForegroundColor Green
}

# Optional: Restart if necessary (done automatically by Install-WindowsUpdate with -AutoReboot)
Write-Host "Check complete. If the system requires a reboot, it will restart automatically." -ForegroundColor Cyan
