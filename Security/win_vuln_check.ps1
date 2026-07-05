#Requires -RunAsAdministrator

$results = [system.collections.generic.List[object]]::new()

function Add-Result {
    param(
        [string]$check,
        [string]$status,
        [string]$detail
    )

    $results.Add([pscustomobject]@{
        Check = $check
        Status = $status
        Detail = $detail
    })
}

#Defender Status
try {
    $av = Get-MPComputerStatus -ErrorAction Stop
    $status = if ($av.AntivirusEnabled -and $av.RealTimeProtectionEnabled) { 'PASS' } else { 'FAIL' }
    Add-Result 'Windows Defender' $status "AntivirusEnabled=$($av.AntivirusEnabled); RealTime=$($av.RealTimeProtectionEnabled)"
}
catch {
    Add-Result 'Windows Defender' 'WARN' "Get-MPComputerStatus Failed: $_"
}

#Firewall Check
$fw = Get-NetFirewallProfile
$fwFail = $fw | Where-Object Enabled -eq $false

$status = if ($fwFail) { 'FAIL' } else {'PASS'}
$detail = ($fw | ForEach-Object {"$($_.Name): Enabled = $($_.Enabled)"}) -join ";"
Add-Result 'Windows Firewall Profiles' $status $detail

#Inbound Rules
$rules = Get-NetFirewallRule -Direction Inbound -Action Allow -Enabled True | 
Get-NetFirewallAddressFilter | Where-Object {$_.RemoteAddress -contains 'Any' -or $_.RemoteAddress -contains '0.0.0.0/0'}
Add-Result 'Inbound Allow Any Rules' $(if($rules){'FAIL'}else{'PASS'}) "Count= $(@($rules).Count)"

#SMBv1
$smb1 = Get-WindowsOptionalFeature -Online -FeatureName SMBProtocol -ErrorAction SilentlyContinue

if($null -ne $smb1) {Add-Result 'SMBv1' $(if($smb1.state -eq 'Enabled'){'FAIL'}else{ 'PASS' } ) "State =" $($smb1.State) } else {Add-Result 'SMBv1' 'WARN' 'Unable to Determine SMBv1 Status'}

#Pending Reboot
$pending = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
Add-Result 'Pending Reboot' $(if($pending) {'WARN'} else{'PASS'}) 'Reboot Pending'


#Local Admins
$admins = Get-LocalGroupMember -Group Administrators -ErrorAction SilentlyContinue
$count = @($admins).Count
Add-Result 'Local Administrators Count' $(if ($count -gt 5) {'WARN'} else {"PASS"}) "Count = $count"

#RDP (Remote Desktop)
$rdp = (Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -ErrorAction SilentlyContinue).fDenyTSConnections
Add-Result 'RDP Enabled' $(if ($rdp -eq 0) {'WARN'} else{'PASS'}) "fDenyTSConnections = $rdp"

#BitLocker
$bl = Get-BitLockerVolume -ErrorAction SilentlyContinue
if ($bl){
    $unprotected = $bl | Where-Object VolumeStatus -ne 'FullyEncrypted'
    Add-Result 'BitLocker' $(if($unprotected) {'WARN'} else {'PASS'}) "VolumesNotFullyEncrypted = $(@($unprotected).Count)"}
else {
    Add-Result 'BitLocker' 'WARN' 'Bitlocker cmdlets unavailable or not configured'
}

#Print Nightmare Vulnerability
function Test-PrintNightmare {
    function Test-PrintSpoolerStatus {
        $spooler = Get-Service -Name "Spooler" -ErrorAction SilentlyContinue

        if ($spooler -and $spooler.Status -eq "Running") {
            return $true
        } else {
            return $false
        }
    }

    function Test-PatchesInstalled {
        $patches = @("KB500945", "KB500953", "KB500951", "KB500947", "KB500946", "KB500948")
        $installed = Get-HotFix | Where-Object { $patches -contains $_.HotFixID }

        if ($installed) {
            return $true
        } else {
            return $false
        }
        }

    function Test-PointAndPrintConfig {
        $regpath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
        $regValues = @("NoWarningNoElevationOnInstall", "UpdatePromptSettings")

        try {
            $reg = Get-ItemProperty -Path $regPath -ErrorAction Stop
            $vulnerable = $false

            foreach ($value in $regValues){
                if($reg.$value -eq 0) {
                    $vulnerable = $true
                }
            }
            return $vulnerable
        } catch {
            return $false
        }
    }

    function Test-DriverInstallRestriction {
        $regpath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\"
        $regvalue = "RestrictDriverInstallationToAdministrators"

        try {
            $reg = Get-ItemProperty -Path $regPath -Name $regvalue - ErrorAction Stop
        
            if ($reg.$regvalue -eq 1) {
                return $true
            } else {
                return $false
            }
        } catch {
            return $false
        }
    }

        $isVulnerable = $false

    if (Test-PrintSpoolerStatus) {
        $isVulnerable = $true
    }

    if (-Not (Test-PatchesInstalled)) {
        $isVulnerable = $true
    }

    if (Test-PointAndPrintConfig) {
        $isVulnerable = $true
    }

    if (-Not (Test-DriverInstallRestriction)) {
        $isVulnerable = $true
    }

    if ($isVulnerable) {
        Add-Result 'PrintNightmare Vulnerabulity' 'WARN' 'System Appears Vulnerable to PrintNightmare Exploit'
    } else {
       Add-Result 'PrintNightmare Vulnerabulity' 'PASS' 'PrintNightmare Vulnerbility not found'
    }
}

#Executes PrintNightmare Check
Test-PrintNightmare

#Output
Write-Output "Date: $(Get-Date)"
Write-Output "System: $env:COMPUTERNAME"
Write-Output "__________________________________"
$results | Format-Table -AutoSize