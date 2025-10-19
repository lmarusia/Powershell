#Script to retrieve and export Active Directory User Information
param (
    [Parameter(Mandatory=$true)]
    [string]$OutputCsvPath
)

# Import Active Directory module
Import-Module ActiveDirectory -ErrorAction Stop

try {
    # Get groups with specific properties to optimize performance
    $Groups = Get-ADGroup -Filter * -Properties Name,Description |
              Where-Object {$_.Name -like "*"} |
              Select-Object -Property Name,Description

    $results = foreach ($group in $Groups) {
        # Get group members with error handling
        try {
            Get-ADGroupMember -Identity $group.Name -ErrorAction Stop | 
                Where-Object { $_.objectClass -eq "user" } | 
                ForEach-Object {
                    # Get specific AD user properties to improve performance
                    $user = Get-ADUser -Identity $_.SamAccountName -Properties `
                        MemberOf,LastLogonDate,PasswordLastSet,PasswordNeverExpires,
                        adminCount,AccountLockoutTime,LockedOut,PasswordExpired,
                        CannotChangePassword,Enabled,PasswordNotRequired,
                        userAccountControl,CanonicalName,CN,DisplayName,
                        DistinguishedName,Description,SamAccountName,HomeDirectory,
                        UserPrincipalName,ScriptPath,Company,Fax,EmailAddress,
                        Pager,GivenName,Surname,Name,Mail,createTimeStamp,
                        logonCount,Department,Title,Office,OfficePhone,Manager,
                        MobilePhone,StreetAddress,Street,City,PostalCode `
                        -ErrorAction Stop
                    
                    [PSCustomObject]@{
                        MemberOf              = $user.MemberOf -join '|'
                        ObjectClass           = $user.ObjectClass
                        LastLogonDate         = $user.LastLogonDate
                        PasswordLastSet       = $user.PasswordLastSet
                        PasswordNeverExpires  = $user.PasswordNeverExpires
                        AdminCount            = $user.adminCount
                        AccountLockoutTime    = $user.AccountLockoutTime
                        LockedOut             = $user.LockedOut
                        PasswordExpired       = $user.PasswordExpired
                        CannotChangePassword  = $user.CannotChangePassword
                        Enabled               = $user.Enabled
                        PasswordNotRequired   = $user.PasswordNotRequired
                        UserAccountControl    = $user.userAccountControl
                        CanonicalName         = $user.CanonicalName
                        CN                    = $user.CN
                        DisplayName           = $user.DisplayName
                        DistinguishedName     = $user.DistinguishedName
                        Description           = $user.Description
                        SamAccountName        = $user.SamAccountName
                        HomeDirectory         = $user.HomeDirectory
                        UserPrincipalName     = $user.UserPrincipalName
                        ScriptPath            = $user.ScriptPath
                        Company               = $user.Company
                        Fax                   = $user.Fax
                        EmailAddress          = $user.EmailAddress
                        Pager                 = $user.Pager
                        GivenName             = $user.GivenName
                        Surname               = $user.Surname
                        Name                  = $user.Name
                        Mail                  = $user.Mail
                        CreateTimeStamp       = $user.createTimeStamp
                        LogonCount            = $user.logonCount
                        Department            = $user.Department
                        Title                 = $user.Title
                        Office                = $user.Office
                        OfficePhone           = $user.OfficePhone
                        Manager               = $user.Manager
                        MobilePhone           = $user.MobilePhone
                        StreetAddress         = $user.StreetAddress
                        Street                = $user.Street
                        City                  = $user.City
                        PostalCode            = $user.PostalCode
                        GroupName             = $group.Name
                        GroupDescription      = $group.Description
                    }
                }
        }
        catch {
            Write-Warning "Error processing group $($group.Name): $_"
            continue
        }
    }

    # Export results to CSV
    $results | Export-Csv -Path $OutputCsvPath -NoTypeInformation -ErrorAction Stop
    Write-Host "Successfully exported results to $OutputCsvPath"
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}