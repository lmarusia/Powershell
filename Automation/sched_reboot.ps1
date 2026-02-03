#Basic Title Display
Write-Host "Schedule Reboot"
Write-Host "_______________________________"

#Variable Declaration
$hour = Read-Host "Hour (0-23)"
$targetTime = (Get-Date -hour $hour -Minute 0 -Second 0).AddDays(1)
$current = Get-Date
$delay = [int](($targetTime - $current).TotalSeconds)

#Checks status of command execution (If reboot is successfully scheduled
try { #Reboot Successfully Scheduled
    #Executes the command to shecudle reboot
    $execute = Start-Process shutdown -ArgumentList "/r /t $delay" -ErrorAction Stop
    Write-Host "The reboot is scheduled for $($targetTime.ToString('dddd, MMMM d at h:mm tt'))" 
}
catch { #Something Prevented Reboot Scheduling
    Write-Host "An Error Has Occured. Reboot Not Scheduled"
}