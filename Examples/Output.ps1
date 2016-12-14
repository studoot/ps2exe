Write-Output "Write-Output"
$DebugPreference = "Continue"
Write-Debug "Write-Debug"
$VerbosePreference = "Continue"
Write-Verbose "Write-Verbose"
Write-Warning "Write-Warning"
Write-Error "Write-Error"

ipconfig | Out-String

Read-Host "Read-Host: Press key to exit"

Write-Host "Write-Host: Done"