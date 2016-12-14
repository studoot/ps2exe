[VOID][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$intptrSize = [System.IntPtr]::Size
if( $intptrSize -eq 4 ) {
	$NULL = [System.Windows.Forms.MessageBox]::Show("This is a 32 bit environment", "Winforms demo for PS2EXE", 0)
} else {
	$NULL = [System.Windows.Forms.MessageBox]::Show("This is a 64 bit environment", "Winforms demo for PS2EXE", 0)
}


if ($PSVersionTable.PSVersion.Major -eq 4)
{
  $VER = "This is PowerShell 4.0"
} elseif ($PSVersionTable.PSVersion.Major -eq 3)
{
  $VER = "This is PowerShell 3.0"
} else {
  if ($PSVersionTable.PSVersion.Major -eq 2)
  {
  	$VER = "This is PowerShell 2.0"
  } else {
		$VER = "This is a unknown PowerShell version."
  }
}
[System.Windows.Forms.MessageBox]::Show($VER, "Winformsdemo for PS2EXE", 0) | Out-Null

[VOID][System.Windows.Forms.MessageBox]::Show("Thread Appartment State is $([System.Threading.Thread]::CurrentThread.GetApartmentState())", "Winforms demo for PS2EXE", 0)

#$credential = Get-Credential #"Testuser"
$credential = $host.ui.PromptForCredential("Authentication required", "Please type user and passwort.", "User", "Computername")

$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password)
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

[VOID][System.Windows.Forms.MessageBox]::Show($credential.UserName + "`n" + $PlainPassword, "Your authentication data:", 0)
