#Admin Utility Script to fetch Failed Logons, Admin Users, and Account Lockouts.
#Switches: -FailedLogons, -Admins, -Lockouts, -All
#Example: .\admin_utility.ps1 -FailedLogons


param (
    [switch]$FailedLogons,
    [switch]$Admins,
    [switch]$Lockouts,
    [switch]$All
)

# Function to Get Failed Logons
function Get-FailedLogons {
    $timeRange = (Get-Date).AddDays(-60)
    $usernameInput = Read-Host "Enter Username to Filter"

    $failedLogons = Get-WinEvent -FilterHashTable @{
        LogName = 'Security'
        ID = 4625
        StartTime = $timeRange
    } | Select-Object TimeCreated, Message, Id, @{Name='UserName'; Expression={
        $_.Message -match 'Account Name:\s+(\S+)' | Out-Null
        $matches[1]
    }}

    $filteredLogins = $failedLogons | Where-Object { $_.UserName -eq $usernameInput }

    $filteredLogins | Format-Table TimeCreated, UserName, Message -AutoSize
}

# Function to Get Admins
function Get-Admins {
    Get-ADGroupMember -Identity "Administrators" | Where-Object { $_.objectClass -eq "user" }
}

# Function to Get Lockouts
function Get-Lockouts {
    $timespan = (Get-Date).AddHours(-24)

    $lockoutEvents = Get-WinEvent -FilterHashTable @{
        LogName = 'Security'
        ID = 4740
        StartTime = $timespan
    } -ErrorAction SilentlyContinue |
    Select-Object TimeCreate,
    @{Name='Account'; Expression={$_.Properties[0].Value}},
    @{Name='Source'; Expression={$_.Properties[1].Value}},
    @{Name='CallerComputer'; Expression={$_.Properties[6].Value}}

    if ($lockoutEvents) {
        Write-Host "`nAccount Lockout Events in 24 Hours: `n" -ForegroundColor Green
        $lockoutEvents | Format-Table -AutoSize -Property @{
            Label = 'Time'
            Expression = {$_.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss')}
        },
        @{
            Label = 'Locked Accounts'
            Expression = {$_.Account}
        },
        @{
            Label = 'Source DC'
            Expression = {$_.Source}
        },
        @{
            Label = 'Caller Computer'
            Expression = {$_.CallerComputer}
        }
    } else {
        Write-Host "`nNo Account Lockout Events Found for 24 Hours" -ForegroundColor Blue
    }

    Write-Host "`nTotal Lockout Events: $($lockoutEvents.Count)" -ForegroundColor Green
}

# Run checks
if ($All) {
    Write-Host "`nRunning all checks..." -ForegroundColor Yellow
    Get-FailedLogons
    Get-Admins
    Get-Lockouts
} else {
    if ($FailedLogons) { Get-FailedLogons }
    if ($Admins)       { Get-Admins }
    if ($Lockouts)     { Get-Lockouts }

    if (-not ($FailedLogons -or $Admins -or $Lockouts)) {
        Write-Host "No parameters were provided. Use -FailedLogons, -Admins, -Lockouts, or -All." -ForegroundColor Red
    }
}
