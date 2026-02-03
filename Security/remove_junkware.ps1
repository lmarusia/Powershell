#Variable Declaration
$user = $env:USERNAME #Identifies Currently Signed On User (User Executing Program)
$junk_list = @{ # List of unwanted software
    "OneStart" = "C:\users\$user\appdata\Local\onestart.ai\"
    "OneLaunch" = "C:\users\$user\appdata\Local\OneLaunch\"
    "PDFix" = "C:\users\$user\Downloads\PDFixers.exe"
}

#For Loop to Cycle Through Each Possible Junkware
foreach ($junk in $junk_list.GetEnumerator()) {
    # Access the Key and Value properties of each entry
    $name   = $junk.Key #Junkware Name (Dictionary Key)
    $path = $junk.Value #Typical Install Path (Dictionary Value)

 
    #Determines if the install location exists on system
    if (Test-Path -Path $path) { #Path Exists (Junkware Is Installed)
        Write-Host "JUNKWARE FOUND - $name"
        Remove-Item "$path" -Force -Recurse
    }
    else { #Path Not Found (Junkware Does Not Appear Installed)
        Write-Host "JUNKWARE NOT FOUND - $name"
    }

}
