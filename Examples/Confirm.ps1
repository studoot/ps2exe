Write-Host "Creating file '.\Test.txt'"
ls > .\test.txt
Write-Host "Removing file '.\Test.txt' depending on confirmation."
del .\Test.txt -confirm
if (Test-Path '.\Test.txt')
{ "File '.\Test.txt' is still there." }
else
{ "File '.\Test.txt' was deleted." }
