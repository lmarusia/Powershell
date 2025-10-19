param (
    [string]$NewComputerName,
    [string]$DomainName,
    [string]$OU = "OU=Computers,DC=domain,DC=com", # Default 
    [string]$DomainAdminUser = "domainadmin",       # Admin Username
    [string]$DomainAdminPassword                     # Password (secure string)
)

# Ensure PowerShell runs with elevated privileges
if (-not [System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) {
    Write-Host "This script requires administrator privileges!" -ForegroundColor Red
    exit
}

# Function to change the computer name
function Change-ComputerName {
    param (
        [string]$NewName
    )

    Write-Host "Renaming computer to '$NewName'..." -ForegroundColor Cyan
    Rename-Computer -NewName $NewName -Force -Restart
}

# Function to join the domain
function Join-Domain {
    param (
        [string]$Domain,
        [string]$OU,
        [string]$AdminUser,
        [System.Security.SecureString]$AdminPassword
    )

    Write-Host "Joining computer to domain '$Domain'..." -ForegroundColor Cyan

    # Create credentials for domain join
    $secureCred = New-Object System.Management.Automation.PSCredential($AdminUser, $AdminPassword)

    Add-Computer -DomainName $Domain -OUPath $OU -Credential $secureCred -Restart
}

# Function to handle user input for domain credentials
function Get-DomainCredentials {
    param (
        [string]$DomainAdminUser
    )

    # Prompt for password securely
    $DomainAdminPassword = Read-Host "Enter password for $DomainAdminUser" -AsSecureString

    return $DomainAdminPassword
}

# Input validation
if (-not $NewComputerName) {
    Write-Host "Please provide a new computer name!" -ForegroundColor Red
    exit
}

if (-not $DomainName) {
    Write-Host "Please provide the domain name!" -ForegroundColor Red
    exit
}

# Get domain credentials if not provided
if (-not $DomainAdminPassword) {
    $DomainAdminPassword = Get-DomainCredentials -DomainAdminUser $DomainAdminUser
}

# Perform actions
try {
    # Step 1: Rename computer
    Change-ComputerName -NewName $NewComputerName

    # Step 2: Join the computer to the domain
    Join-Domain -Domain $DomainName -OU $OU -AdminUser $DomainAdminUser -AdminPassword $DomainAdminPassword

    Write-Host "Computer successfully renamed and added to the domain!" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
