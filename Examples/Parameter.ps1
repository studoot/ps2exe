Param([STRING]$Text = "defaultvalue", [INT]$NUMBER = -1, [SWITCH]$SELECT, [ARRAY] $STRARRAY)

Write-Host "Text: $Text`nNumber: $NUMBER`nSelect: $SELECT"

if ($STRARRAY)
{ "Array: $STRARRAY" }
