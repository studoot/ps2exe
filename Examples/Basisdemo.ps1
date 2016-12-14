Write-Host "Console demo for PS2EXE" -f Yellow
Write-Host

$intptrSize = [System.IntPtr]::Size
if ($intptrSize -eq 4)
{
	Write-Host "This is a 32 bit environment" -ForegroundColor DarkYellow
} else {
	Write-Host "This is a 64 bit environment" -ForegroundColor Green
}
Write-Host

if ($PSVersionTable.PSVersion.Major -eq 4)
{
	Write-Host "This is PowerShell 4.0" -fore Cyan
} elseif ($PSVersionTable.PSVersion.Major -eq 3)
{
  Write-Host "This is PowerShell 3.0" -fore Red
} else {
  if ($PSVersionTable.PSVersion.Major -eq 2)
  {
  	Write-Host "This is PowerShell 2.0" -fore DarkCyan
  } else {
  	Write-Host "This is a unknown PowerShell version." -fore Blue
  }
}
Write-Host

Write-Host "Thread Appartment State is $([System.Threading.Thread]::CurrentThread.GetApartmentState())"
Write-Host

$credential = Get-Credential #"Testuser"
#$credential = $host.ui.PromptForCredential("Authentication required", "Please type user and passwort.", "User", "Computername")

Write-Host "`n`nYour authentication data:" -Fore Magenta

$credential
Write-Host

$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password)
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
"Your password: " + $PlainPassword

Write-Host

$Wert = Read-Host "Type in a string"
"Your input was: $Wert"

$NULL = Read-Host "Press enter to exit"
