# Function to calculate the size of files
function Get-DirectorySize {
    param (
        [string]$path
    )

    # Recursively searches directory
    $files = Get-ChildItem -Path $path -Recurse -File
    $totalSize = 0

    # Calculates Total Size
    foreach ($file in $files) {
        $totalSize += $file.Length
    }

    return $totalSize
}

# Function to get the size/sorts directories
function Get-LargestDirectories {
    param (
        [string]$path = "C:\",  # Default path
        [int]$depth = 3  # Depth to search
    )

    # Defines Array
    $dirSizes = @()

    $directories = Get-ChildItem -Path $path -Directory -Recurse | Where-Object { $_.PSIsContainer -eq $true }

    $directories = $directories | Where-Object { ($_ | Split-Path -Parent).Split('\').Count -le $depth + 1 }

    foreach ($dir in $directories) {
        $size = Get-DirectorySize -path $dir.FullName
        $dirSizes += [PSCustomObject]@{
            Directory = $dir.FullName
            SizeMB    = [math]::round($size / 1MB, 2)
            SizeBytes = $size
        }
    }

    # Sort top 15
    $dirSizes | Sort-Object -Property SizeBytes -Descending | Select-Object -First 15
}

# Function to get the largest files
function Get-LargestFiles {
    param (
        [string]$path = "C:\",  # Default path to scan
        [int]$topN = 15  # How many top files to return
    )

    $files = Get-ChildItem -Path $path -Recurse -File

    $files | Sort-Object -Property Length -Descending | Select-Object -First $topN | Select-Object Name, @{Name="SizeMB";Expression={[math]::round($_.Length / 1MB, 2)}} 
}

# Function to get the largest apps
function Get-LargestInstalledApps {
    param (
        [int]$topN = 15  # How many top apps to return
    )

    $apps = Get-WmiObject -Class Win32_Product | Select-Object Name, @{Name="SizeMB";Expression={[math]::round($_.InstallSize / 1MB, 2)}} 

    $apps | Sort-Object -Property SizeMB -Descending | Select-Object -First $topN
}

# Main function to run all checks and output results
function Get-DiskUsageReport {
    param (
        [string]$path = "C:\",
        [int]$depth = 3,  # Depth of directory
        [int]$topN = 15  # Number of top results to display
    )

    Write-Host "Getting Largest Directories (Top 15):" -ForegroundColor Cyan
    $largestDirs = Get-LargestDirectories -path $path -depth $depth
    $largestDirs | Format-Table -AutoSize

    Write-Host "`nGetting Largest Files (Top 15):" -ForegroundColor Cyan
    $largestFiles = Get-LargestFiles -path $path -topN $topN
    $largestFiles | Format-Table -AutoSize

    Write-Host "`nGetting Largest Installed Apps (Top 15):" -ForegroundColor Cyan
    $largestApps = Get-LargestInstalledApps -topN $topN
    $largestApps | Format-Table -AutoSize
}

#Executes
Get-DiskUsageReport -path "C:\" -depth 3 -topN 15
