$inputXML = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    x:Name="Window"
    Title="MainWindow"
    Width="640" Height="480">

    <Grid x:Name="LayoutRoot">
        <TextBox x:Name="testBox" HorizontalAlignment="Left"
                 Margin="26.782,48.626,0,0" TextWrapping="Wrap"
                 Text="New label text" VerticalAlignment="Top" Width="130.22"/>
        <Label x:Name="testLabel" Content="User Search" HorizontalAlignment="Left"
                 Margin="20.666,22.666,0,0" VerticalAlignment="Top"/>
        <Button x:Name="testButton" Content="Change It!" HorizontalAlignment="Left"
                 Margin="26.782,85,0,0" VerticalAlignment="Top" Width="75"/>
    </Grid>
</Window>
"@
 
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
    $reader=(New-Object System.Xml.XmlNodeReader $xaml) 
  try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch [System.Management.Automation.MethodInvocationException] {
    Write-Warning "We ran into a problem with the XAML code.  Check the syntax for this control..."
    write-host $error[0].Exception.Message -ForegroundColor Red
    if ($error[0].Exception.Message -like "*button*"){
        write-warning "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n"}
}
catch{#if it broke some other way <img draggable="false" class="emoji" alt="" src="https://s0.wp.com/wp-content/mu-plugins/wpcom-smileys/twemoji/2/svg/1f600.svg">
    Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
        }
 
#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================
 
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}
 
Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable WPF*
}
 
#===========================================================================
# Use this space to add code to the various form elements in your GUI
#===========================================================================
                                                                    
$WPFtestButton.Add_Click({$WPFtestButton.Content = $WPFtestBox.Text })

#===========================================================================
# Shows the form
#===========================================================================


$Form.ShowDialog() | out-null