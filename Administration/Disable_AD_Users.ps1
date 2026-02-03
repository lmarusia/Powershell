#Script To Disable Inactive AD User Accounts Based On Desired Threshold (Defaults to 90 Days)
#Usage -
#(Default - 90 Days): .\disable_AD_Users
#(6 Months): .\Disable_AD_Users -Age 180


#Parameters (Switch to Define Age)
param (
    [int]$Age = 90 #Defaults to 90 Days
)


#Imports
Import-Module ActiveDirectory

#Variable Declaration
$current = Get-Date
$target
$allUsers = @()
$stale = @()

$target = $current.AddDays(-$age) #Establishes Threshold

$users = Get-ADUser -Filter * -Properties LastLogonDate #Retrieves All AD Users

#Cycles Through Retrieved Users
foreach ($user in $users) {

    $status = if ($user.LastLogonDate) {
        if ($user.LastLogonDate -gt $target) { #User Has Logged In (Records Info And Skips)
            "User has logged on in the last $age days"
        } else { #User Has Not Logged In (Records Info And Adds to Disable List
            $staleUsers += $user
            "User has NOT logged on in the last $age days"
        }
    } else { #User Never Logged In (Records Info And Adds to Disable List
        $staleUsers += $user
        "User has NEVER logged in"
    }

    #Defines Object to Store Information for CSV Export
    $allUsers += [PSCustomObject]@{
        acct_name = $user.SamAccountName
        lastLogon = $user.LastLogonDate
        status    = $status
    }
}

#Cycles Through Stale Users List
foreach ($user in $staleUsers) {
    try { #Disables
        Disable-ADAccount -Identity $user.SamAccountName
    } catch { #Error
        Write-Warning "Failed to disable $($user.SamAccountName): $_"
    }
}

#Exports to CSV
$allUsers | Export-CSV -Path "$($current.ToString('yyyyMMdd'))_users.csv" -NoTypeInformation