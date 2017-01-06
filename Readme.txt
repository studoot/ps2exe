PS2EXE-GUI v0.5.0.2
Release: 2017-01-02

Overworking of the great script of Igor Karstein with GUI support by Markus Scholtes. 

The GUI output and input is activated with one switch, real windows executables 
are generated.

https://gallery.technet.microsoft.com/scriptcenter/PS2EXE-GUI-Convert-e7cb69d5


All of you know the fabulous script PS2EXE by Ingo Karstein you can download here: PS2EXE : "Convert" PowerShell Scripts to EXE Files.

Unfortunately Ingo seems to have stopped working on his script so I overworked his script with some error fixes, improvements and output support for non-console WinForms scripts (parameter -noConsole to ps2exe.ps1).

 

I made the following important fixes and improvements:

Update v0.5.0.2:
- STA or MTA mode is used corresponding to the powershell version when not specified (V3 or higher: STA, V2: MTA)
  This prevents problems with COM and some graphic dialogs
- icon file is seeked in the correct directory (thanks to Stuart Dootson)
Update v0.5.0.1: - interfering PROGRESS handler removed
- treats Powershell 5 or above like Powershell 4
- method SetBufferContents for Clear-Host added
- the console output methods do not use black background and white foreground, but use the actual colors now
- new, corrected and much expanded parser for command line parameters
- input and output file are seeked and generated in the correct directory
- check that input file is not the same as the output file
- doubled VERBOSE and WARNING handler removed

Full list of changes and fixes in Changes.txt.

 

GUI support:

- expanded every output and input function like Write-Host, Write-Output, Write-Error, Out-Default, Prompt, ReadLine to use WinForms message boxes or input boxes automatically when compiling a GUI application (Write-Progress is still missing)
- no console windows appears, real windows executables are generated
- just compile with switch "-noConsole" for this feature (i.e. .\ps2exe.ps1 .\output.ps1 .\output.exe -noConsole)
- see remarks below for formatting of output in GUI mode


Compile all of the examples in the Examples sub directory with

BuildExamples.bat

Every script will be compiled to a console and a GUI version.


Remarks:

GUI mode output formatting:
Per default output of commands are formatted line per line (as an array of strings). When your command generates 10 lines of output and you use GUI output, 10 message boxes will appear each awaitung for an OK. To prevent this pipe your command to the comandlet Out-String. This will convert the output to a string array with 10 lines, all output will be shown in one message box (for example: dir C:\ | Out-String).

Config files:
PS2EXE create config files with the name of the generated executable + ".config". In most cases those config files are not necessary, they are a manifest that tells which .Net Framework version should be used. As you will usually use the actual .Net Framework, try running your excutable without the config file.

Password security:
Never store passwords in your compiled script! One can simply decompile the script with the parameter -extract. For example
Output.exe -extract:C:\Output.ps1
will decompile the script stored in Output.exe.
