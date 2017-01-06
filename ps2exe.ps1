Param([string]$inputFile=$null, [string]$outputFile=$null, [switch]$verbose, [switch] $debug, [switch]$runtime20, [switch]$runtime30, [switch]$runtime40, [switch]$x86, [switch]$x64, [int]$lcid, [switch]$Sta, [switch]$Mta, [switch]$noConsole, [switch]$nested, [string]$iconFile=$null, [switch] $elevated=$FALSE, [string]$title=$null, [string]$description=$null, [string]$company=$null, [string]$product=$null, [string]$copyright=$null, [string]$version=$null)

<################################################################################>
<##                                                                            ##>
<##      PS2EXE-GUI v0.5.0.1                                                   ##>
<##      Written by: Ingo Karstein (http://blog.karstein-consulting.com)       ##>
<##      Reworked and GUI support by Markus Scholtes                           ##>
<##                                                                            ##>
<##      This script is released under Microsoft Public Licence                ##>
<##          that can be downloaded here:                                      ##>
<##          http://www.microsoft.com/opensource/licenses.mspx#Ms-PL           ##>
<##                                                                            ##>
<################################################################################>


if (!$nested)
{
	Write-Host "PS2EXE-GUI v0.6.0.1 by Ingo Karstein, reworked and GUI support by Markus Scholtes, further modifications by Stuart Dootson"
}
else
{
	Write-Host "PowerShell 2.0 environment started..."
}
Write-Host ""

if ($runtime20 -eq $TRUE -and $runtime30 -eq $TRUE)
{
	Write-Host "You cannot use switches -runtime20 and -runtime30 at the same time!"
	exit -1
}

if ($Sta -eq $TRUE -and $Mta -eq $TRUE)
{
	Write-Host "You cannot use switches -Sta and -Mta at the same time!"
	exit -1
}

if ([string]::IsNullOrEmpty($inputFile) -or [string]::IsNullOrEmpty($outputFile))
{
	Write-Host "Usage:"
	Write-Host ""
	Write-Host "powershell.exe -command ""&'.\ps2exe.ps1' [-inputFile] '<file_name>' [-outputFile] '<file_name>'"
	Write-Host "               [-verbose] [-debug] [-runtime20|-runtime30|-runtime40] [-lcid <id>] [-x86|-x64] [-Sta|-Mta]"
	Write-Host "               [-noConsole] [-iconFile '<file_name>'] [-elevated]"
	Write-Host "               [-title '<title-string>'] [-description '<description-string>']  [-company '<company-string>']"
	Write-Host "               [-product '<product-string>'] [-copyright '<copyright-string>']  [-version '<version-string>']"""
	Write-Host ""
	Write-Host "   inputFile = powerShell script that you want to convert to EXE"
	Write-Host "  outputFile = destination EXE file name"
	Write-Host "     verbose = output verbose informations - if any"
	Write-Host "       debug = generate debug informations for output file"
	Write-Host "   runtime20 = this switch forces PS2EXE to create a config file for the generated EXE that contains the"
	Write-Host "               ""supported .NET Framework versions"" setting for .NET Framework 2.0 for PowerShell 2.0"
	Write-Host "   runtime30 = this switch forces PS2EXE to create a config file for the generated EXE that contains the"
	Write-Host "               ""supported .NET Framework versions"" setting for .NET Framework 4.0 for PowerShell 3.0"
	Write-Host "   runtime40 = this switch forces PS2EXE to create a config file for the generated EXE that contains the"
	Write-Host "               ""supported .NET Framework versions"" setting for .NET Framework 4.0 for PowerShell 4.0"
	Write-Host "        lcid = location ID for the compiled EXE. Current user culture if not specified."
	Write-Host "         x86 = compile for 32-bit runtime only"
	Write-Host "         x64 = compile for 64-bit runtime only"
	Write-Host "         sta = Single Thread Apartment Mode"
	Write-Host "         mta = Multi Thread Apartment Mode"
	Write-Host "   noConsole = the resulting EXE file will be a Windows Forms app without a console window."
	Write-Host "    iconFile = icon for the compiled EXE"
	Write-Host "    elevated = include manifest to request admin privileges"
	Write-Host "       title = title to include in assembly information"
	Write-Host " description = description to include in assembly information"
	Write-Host "     company = company name to include in assembly information"
	Write-Host "     product = product name to include in assembly information"
	Write-Host "   copyright = copyright to include in assembly information"
	Write-Host "     version = version to include in assembly information"

	Write-Host ""
	Write-Host "Input file or output file not specified!"
	exit -1
}

$psversion = 0
if ($PSVersionTable.PSVersion.Major -ge 4)
{
	$psversion = 4
	Write-Host "You are using PowerShell 4.0 or above."
}

if ($PSVersionTable.PSVersion.Major -eq 3)
{
	$psversion = 3
	Write-Host "You are using PowerShell 3.0."
}

if ($PSVersionTable.PSVersion.Major -eq 2)
{
	$psversion = 2
	Write-Host "You are using PowerShell 2.0."
}

if ($psversion -eq 0)
{
	Write-Host "The powershell version is unknown!"
	exit -1
}

# retrieve absolute paths independetn if path is given relative oder absolute
$inputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($inputFile)
$iconFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($iconFile)
$outputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outputFile)

if (!(Test-Path $inputFile -PathType Leaf))
{
	Write-Host "Input file $($inputFile) not found!"
	exit -1
}

if ($inputFile -eq $outputFile)
{
	Write-Host "Input file is identical to output file!"
	exit -1
}

if (!(Test-Path $iconFile -PathType Leaf))
{
	Write-Host "Input file $($iconFile) not found!"
	exit -1
}

if (!$runtime20 -and !$runtime30 -and !$runtime40)
{
	if ($psversion -eq 4)
	{
		$runtime40 = $TRUE
	}
	elseif ($psversion -eq 3)
	{
		$runtime30 = $TRUE
	}
	else
	{
		$runtime20 = $TRUE
	}
}

if ($psversion -ge 3 -and $runtime20)
{
	Write-Host "To create a EXE file for PowerShell 2.0 on PowerShell 3.0/4.0 this script now launches PowerShell 2.0..."
	Write-Host ""

	$arguments = "-inputFile '$($inputFile)' -outputFile '$($outputFile)' -nested "

	if ($verbose) { $arguments += "-verbose "}
	if ($debug) { $arguments += "-debug "}
	if ($runtime20) { $arguments += "-runtime20 "}
	if ($x86) { $arguments += "-x86 "}
	if ($x64) { $arguments += "-x64 "}
	if ($lcid) { $arguments += "-lcid $lcid "}
	if ($Sta) { $arguments += "-Sta "}
	if ($Mta) { $arguments += "-Mta "}
	if ($noConsole) { $arguments += "-noConsole "}
	if (!([string]::IsNullOrEmpty($iconFile))) { $arguments += "-iconFile '$($iconFile)' "}

	$jobScript = @"
."$($PSHOME)\powershell.exe" -version 2.0 -command "&'$($MyInvocation.MyCommand.Path)' $($arguments)"
"@
	Invoke-Expression $jobScript

	exit 0
}

if ($psversion -lt 3 -and $runtime30)
{
	Write-Host "You need to run ps2exe in an powershell 3.0 environment to use parameter -runtime30"
	Write-Host
	exit -1
}

if ($psversion -lt 4 -and $runtime40)
{
	Write-Host "You need to run ps2exe in an powershell 4.0 environment to use parameter -runtime40"
	Write-Host
	exit -1
}

Write-Host ""

$type = ('System.Collections.Generic.Dictionary`2') -as "Type"
$type = $type.MakeGenericType( @( ("System.String" -as "Type"), ("system.string" -as "Type") ) )
$o = [Activator]::CreateInstance($type)

if ($psversion -eq 3 -or $psversion -eq 4)
{
	$o.Add("CompilerVersion", "v4.0")
}
else
{
	$o.Add("CompilerVersion", "v2.0")
}

$referenceAssembies = @("System.dll")
$referenceAssembies += ([System.AppDomain]::CurrentDomain.GetAssemblies() | ? { $_.ManifestModule.Name -ieq "Microsoft.PowerShell.ConsoleHost" } | Select -First 1).Location
$referenceAssembies += ([System.AppDomain]::CurrentDomain.GetAssemblies() | ? { $_.ManifestModule.Name -ieq "System.Management.Automation.dll" } | Select -First 1).Location

if ($runtime30 -or $runtime40)
{
	$n = New-Object System.Reflection.AssemblyName("System.Core, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[System.AppDomain]::CurrentDomain.Load($n) | Out-Null
	$referenceAssembies += ([System.AppDomain]::CurrentDomain.GetAssemblies() | ? { $_.ManifestModule.Name -ieq "System.Core.dll" } | Select -First 1).Location
}

if ($noConsole)
{
	$n = New-Object System.Reflection.AssemblyName("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	if ($runtime30 -or $runtime40)
	{
		$n = New-Object System.Reflection.AssemblyName("System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	}
	[System.AppDomain]::CurrentDomain.Load($n) | Out-Null

	$n = New-Object System.Reflection.AssemblyName("System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
	if ($runtime30 -or $runtime40)
	{
		$n = New-Object System.Reflection.AssemblyName("System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
	}
	[System.AppDomain]::CurrentDomain.Load($n) | Out-Null

	$referenceAssembies += ([System.AppDomain]::CurrentDomain.GetAssemblies() | ? { $_.ManifestModule.Name -ieq "System.Windows.Forms.dll" } | Select -First 1).Location
	$referenceAssembies += ([System.AppDomain]::CurrentDomain.GetAssemblies() | ? { $_.ManifestModule.Name -ieq "System.Drawing.dll" } | Select -First 1).Location
}

$platform = "anycpu"
if ($x64 -and !$x86) { $platform = "x64" } else { if ($x86 -and !$x64) { $platform = "x86" }}

$cop = (New-Object Microsoft.CSharp.CSharpCodeProvider($o))
$cp = New-Object System.CodeDom.Compiler.CompilerParameters($referenceAssembies, $outputFile)
$cp.GenerateInMemory = $FALSE
$cp.GenerateExecutable = $TRUE

$iconFileParam = ""
if (!([string]::IsNullOrEmpty($iconFile)))
{
	$iconFileParam = "`"/win32icon:$($iconFile)`""
}
$manifestParam = ""
if ($elevated)
{
	$runElevatedManifestPath = Resolve-Path -Path $(Join-Path -Path $PSScriptRoot -ChildPath runElevated.manifest)
	$manifestParam = "`"/win32manifest:$($runElevatedManifestPath)`""
}
$cp.CompilerOptions = "/platform:$($platform) /target:$( if ($noConsole){'winexe'}else{'exe'}) $($iconFileParam) $($manifestParam)"

$cp.IncludeDebugInformation = $debug

if ($debug)
{
	#$cp.TempFiles.TempDir = (Split-Path $inputFile)
	$cp.TempFiles.KeepFiles = $TRUE
}

Write-Host "Reading input file " -NoNewline
Write-Host $inputFile
Write-Host ""
$content = Get-Content -LiteralPath ($inputFile) -Encoding UTF8 -ErrorAction SilentlyContinue
if ($content -eq $null)
{
	Write-Host "No data found. May be read error or file protected."
	exit -2
}
$scriptInp = [string]::Join("`r`n", $content)
$script = [System.Convert]::ToBase64String(([System.Text.Encoding]::UTF8.GetBytes($scriptInp)))

#region program frame
$culture = ""

if ($lcid)
{
	$culture = @"
	System.Threading.Thread.CurrentThread.CurrentCulture = System.Globalization.CultureInfo.GetCultureInfo($lcid);
	System.Threading.Thread.CurrentThread.CurrentUICulture = System.Globalization.CultureInfo.GetCultureInfo($lcid);
"@
}

$programFrame = @"
// Simple PowerShell host created by Ingo Karstein (http://blog.karstein-consulting.com) for PS2EXE
// Reworked and GUI support by Markus Scholtes

using System;
using System.Collections.Generic;
using System.Text;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using PowerShell = System.Management.Automation.PowerShell;
using System.Globalization;
using System.Management.Automation.Host;
using System.Security;
using System.Reflection;
using System.Runtime.InteropServices;
$(if ($noConsole) {@"
using System.Windows.Forms;
using System.Drawing;
"@ })
using System.Reflection;

$(if ($title) {@"
[assembly:AssemblyTitle("$title")]
"@ })

$(if ($description) {@"
[assembly:AssemblyDescription("$description")]
"@ })

$(if ($company) {@"
[assembly:AssemblyCompany("$company")]
"@ })

$(if ($product) {@"
[assembly:AssemblyProduct("$product")]
"@ })

$(if ($copyright) {@"
[assembly:AssemblyCopyright("$copyright")]
"@ })

$(if ($version) {@"
[assembly:AssemblyVersion("$version")]
[assembly:AssemblyFileVersion("$version")]
"@ })

namespace ik.PowerShell
{
$(if ($noConsole) {@"
	internal class CredentialForm
	{
		// http://www.pinvoke.net/default.aspx/credui/CredUnPackAuthenticationBuffer.html
		// http://www.pinvoke.net/default.aspx/credui/CredUIPromptForWindowsCredentials.html
		// http://www.pinvoke.net/default.aspx/credui.creduipromptforcredentials

		[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
		private struct CREDUI_INFO
		{
			public int cbSize;
			public IntPtr hwndParent;
			public string pszMessageText;
			public string pszCaptionText;
			public IntPtr hbmBanner;
		}

		[Flags]
		enum CREDUI_FLAGS
		{
			INCORRECT_PASSWORD = 0x1,
			DO_NOT_PERSIST = 0x2,
			REQUEST_ADMINISTRATOR = 0x4,
			EXCLUDE_CERTIFICATES = 0x8,
			REQUIRE_CERTIFICATE = 0x10,
			SHOW_SAVE_CHECK_BOX = 0x40,
			ALWAYS_SHOW_UI = 0x80,
			REQUIRE_SMARTCARD = 0x100,
			PASSWORD_ONLY_OK = 0x200,
			VALIDATE_USERNAME = 0x400,
			COMPLETE_USERNAME = 0x800,
			PERSIST = 0x1000,
			SERVER_CREDENTIAL = 0x4000,
			EXPECT_CONFIRMATION = 0x20000,
			GENERIC_CREDENTIALS = 0x40000,
			USERNAME_TARGET_CREDENTIALS = 0x80000,
			KEEP_USERNAME = 0x100000,
		}

		public enum CredUIReturnCodes
		{
			NO_ERROR = 0,
			ERROR_CANCELLED = 1223,
			ERROR_NO_SUCH_LOGON_SESSION = 1312,
			ERROR_NOT_FOUND = 1168,
			ERROR_INVALID_ACCOUNT_NAME = 1315,
			ERROR_INSUFFICIENT_BUFFER = 122,
			ERROR_INVALID_PARAMETER = 87,
			ERROR_INVALID_FLAGS = 1004,
		}

		[DllImport("credui")]
		private static extern CredUIReturnCodes CredUIPromptForCredentials(ref CREDUI_INFO creditUR,
			string targetName,
			IntPtr reserved1,
			int iError,
			StringBuilder userName,
			int maxUserName,
			StringBuilder password,
			int maxPassword,
			[MarshalAs(UnmanagedType.Bool)] ref bool pfSave,
			CREDUI_FLAGS flags);

		public class UserPwd
		{
			public string User = string.Empty;
			public string Password = string.Empty;
			public string Domain = string.Empty;
		}

		internal static UserPwd PromptForPassword(string caption, string message, string target, string user, PSCredentialTypes credTypes, PSCredentialUIOptions options)
		{
			// Setup the flags and variables
			StringBuilder userPassword = new StringBuilder(), userID = new StringBuilder(user, 128);
			CREDUI_INFO credUI = new CREDUI_INFO();
			credUI.cbSize = Marshal.SizeOf(credUI);
			bool save = false;

			CREDUI_FLAGS flags = CREDUI_FLAGS.DO_NOT_PERSIST;
			if ((credTypes & PSCredentialTypes.Domain) != PSCredentialTypes.Domain)
			{
				flags |= CREDUI_FLAGS.GENERIC_CREDENTIALS;
				if ((options & PSCredentialUIOptions.AlwaysPrompt) == PSCredentialUIOptions.AlwaysPrompt)
				{
					flags |= CREDUI_FLAGS.ALWAYS_SHOW_UI;
				}
			}

			// Prompt the user
			CredUIReturnCodes returnCode = CredUIPromptForCredentials(ref credUI, target, IntPtr.Zero, 0, userID, 128, userPassword, 128, ref save, flags);

			if (returnCode == CredUIReturnCodes.NO_ERROR)
			{
				UserPwd ret = new UserPwd();
				ret.User = userID.ToString();
				ret.Password = userPassword.ToString();
				ret.Domain = "";
				return ret;
			}

			return null;
		}
	}
"@ })

	internal class PS2EXEHostRawUI : PSHostRawUserInterface
	{
$(if ($noConsole){ @"
		// Speicher für Konsolenfarben bei GUI-Output werden gelesen und gesetzt, aber im Moment nicht genutzt (for future use)
		private ConsoleColor ncBackgroundColor = ConsoleColor.White;
		private ConsoleColor ncForegroundColor = ConsoleColor.Black;
"@ })

		public override ConsoleColor BackgroundColor
		{
$(if (!$noConsole){ @"
			get
			{
				return Console.BackgroundColor;
			}
			set
			{
				Console.BackgroundColor = value;
			}
"@ } else {@"
			get
			{
				return ncBackgroundColor;
			}
			set
			{
				ncBackgroundColor = value;
			}
"@ })
		}

		public override System.Management.Automation.Host.Size BufferSize
		{
			get
			{
$(if (!$noConsole){ @"
					return new System.Management.Automation.Host.Size(Console.BufferWidth, Console.BufferHeight);
"@ } else {@"
					// return default value for Winforms. If no valid value is returned WriteLine will not be called
					return new System.Management.Automation.Host.Size(120, 50);
"@ })
			}
			set
			{
$(if (!$noConsole){ @"
				Console.BufferWidth = value.Width;
				Console.BufferHeight = value.Height;
"@ })
			}
		}

		public override Coordinates CursorPosition
		{
			get
			{
$(if (!$noConsole){ @"
				return new Coordinates(Console.CursorLeft, Console.CursorTop);
"@ } else {@"
				// Dummywert für Winforms zurückgeben.
				return new Coordinates(0, 0);
"@ })
			}
			set
			{
$(if (!$noConsole){ @"
				Console.CursorTop = value.Y;
				Console.CursorLeft = value.X;
"@ })
			}
		}

		public override int CursorSize
		{
			get
			{
$(if (!$noConsole){ @"
				return Console.CursorSize;
"@ } else {@"
				// Dummywert für Winforms zurückgeben.
				return 25;
"@ })
			}
			set
			{
$(if (!$noConsole){ @"
				Console.CursorSize = value;
"@ })
			}
		}

		public override void FlushInputBuffer()
		{
			// Nothing to do
		}

		public override ConsoleColor ForegroundColor
		{
$(if (!$noConsole){ @"
			get
			{
				return Console.ForegroundColor;
			}
			set
			{
				Console.ForegroundColor = value;
			}
"@ } else {@"
			get
			{
				return ncForegroundColor;
			}
			set
			{
				ncForegroundColor = value;
			}
"@ })
		}

		public override BufferCell[,] GetBufferContents(System.Management.Automation.Host.Rectangle rectangle)
		{
			throw new Exception("Not implemented: ik.PowerShell.PS2EXEHostRawUI.GetBufferContents");
		}

		public override bool KeyAvailable
		{
			get
			{
$(if (!$noConsole) {@"
				return Console.KeyAvailable;
"@ } else {@"
				return true;
"@ })
			}
		}

		public override System.Management.Automation.Host.Size MaxPhysicalWindowSize
		{
			get
			{
$(if (!$noConsole){ @"
				return new System.Management.Automation.Host.Size(Console.LargestWindowWidth, Console.LargestWindowHeight);
"@ } else {@"
				// Dummy-Wert für Winforms
				return new System.Management.Automation.Host.Size(240, 84);
"@ })
			}
		}

		public override System.Management.Automation.Host.Size MaxWindowSize
		{
			get
			{
$(if (!$noConsole){ @"
				return new System.Management.Automation.Host.Size(Console.BufferWidth, Console.BufferWidth);
"@ } else {@"
				// Dummy-Wert für Winforms
				return new System.Management.Automation.Host.Size(120, 84);
"@ })
			}
		}

		public override KeyInfo ReadKey(ReadKeyOptions options)
		{
$(if (!$noConsole) {@"
			ConsoleKeyInfo cki = Console.ReadKey((options & ReadKeyOptions.NoEcho)!=0);

			ControlKeyStates cks = 0;
			if ((cki.Modifiers & ConsoleModifiers.Alt) != 0)
				cks |= ControlKeyStates.LeftAltPressed | ControlKeyStates.RightAltPressed;
			if ((cki.Modifiers & ConsoleModifiers.Control) != 0)
				cks |= ControlKeyStates.LeftCtrlPressed | ControlKeyStates.RightCtrlPressed;
			if ((cki.Modifiers & ConsoleModifiers.Shift) != 0)
				cks |= ControlKeyStates.ShiftPressed;
			if (Console.CapsLock)
				cks |= ControlKeyStates.CapsLockOn;
			if (Console.NumberLock)
				cks |= ControlKeyStates.NumLockOn;

			return new KeyInfo((int)cki.Key, cki.KeyChar, cks, (options & ReadKeyOptions.IncludeKeyDown)!=0);
"@ } else {@"
			if ((options & ReadKeyOptions.IncludeKeyDown)!=0)
				return ReadKeyBox.Show("", "", true);
			else
				return ReadKeyBox.Show("", "", false);
"@ })
		}

		public override void ScrollBufferContents(System.Management.Automation.Host.Rectangle source, Coordinates destination, System.Management.Automation.Host.Rectangle clip, BufferCell fill)
		{
			throw new Exception("Not implemented: ik.PowerShell.PS2EXEHostRawUI.ScrollBufferContents");
		}

		public override void SetBufferContents(System.Management.Automation.Host.Rectangle rectangle, BufferCell fill)
		{
$(if (!$noConsole){ @"
			// using a trick: move the buffer out of the screen, the source area gets filled with the char fill.Character
			if (rectangle.Left >= 0)
				Console.MoveBufferArea(rectangle.Left, rectangle.Top, rectangle.Right-rectangle.Left, rectangle.Bottom-rectangle.Top, BufferSize.Width, BufferSize.Height, fill.Character, fill.ForegroundColor, fill.BackgroundColor);
			else
			{ // Clear-Host: move all content off the screen
				Console.MoveBufferArea(0, 0, BufferSize.Width, BufferSize.Height, BufferSize.Width, BufferSize.Height, fill.Character, fill.ForegroundColor, fill.BackgroundColor);
			}
"@ })
		}

		public override void SetBufferContents(Coordinates origin, BufferCell[,] contents)
		{
			throw new Exception("Not implemented: ik.PowerShell.PS2EXEHostRawUI.SetBufferContents");
		}

		public override Coordinates WindowPosition
		{
			get
			{
				Coordinates s = new Coordinates();
$(if (!$noConsole){ @"
				s.X = Console.WindowLeft;
				s.Y = Console.WindowTop;
"@ } else {@"
				// Dummy-Wert für Winforms
				s.X = 0;
				s.Y = 0;
"@ })
				return s;
			}
			set
			{
$(if (!$noConsole){ @"
				Console.WindowLeft = value.X;
				Console.WindowTop = value.Y;
"@ })
			}
		}

		public override System.Management.Automation.Host.Size WindowSize
		{
			get
			{
				System.Management.Automation.Host.Size s = new System.Management.Automation.Host.Size();
$(if (!$noConsole){ @"
				s.Height = Console.WindowHeight;
				s.Width = Console.WindowWidth;
"@ } else {@"
				// Dummy-Wert für Winforms
				s.Height = 50;
				s.Width = 120;
"@ })
				return s;
			}
			set
			{
$(if (!$noConsole){ @"
				Console.WindowWidth = value.Width;
				Console.WindowHeight = value.Height;
"@ })
			}
		}

		public override string WindowTitle
		{
			get
			{
$(if (!$noConsole){ @"
				return Console.Title;
"@ } else {@"
				return System.AppDomain.CurrentDomain.FriendlyName;
"@ })
			}
			set
			{
$(if (!$noConsole){ @"
				Console.Title = value;
"@ })
			}
		}
	}

$(if ($noConsole){ @"
	public class InputBox
	{
		public static DialogResult Show(string sTitle, string sPrompt, ref string sValue, bool bSecure)
		{
		  // Controls erzeugen
		  Form form = new Form();
		  Label label = new Label();
		  TextBox textBox = new TextBox();
		  Button buttonOk = new Button();
		  Button buttonCancel = new Button();

		  // Am Label orientieren sich die Größen und Positionen
		  // Dieses Control also zuerst fertigstellen
			if (string.IsNullOrEmpty(sPrompt))
			{
				if (bSecure)
					label.Text = "Secure input:   ";
				else
					label.Text = "Input:          ";
			}
			else
			  label.Text = sPrompt;
		  label.Location = new Point(9, 19);
		  label.AutoSize = true;
		  // erst durch Add() wird die Größe des Labels ermittelt
		  form.Controls.Add(label);

		  // Textbox erzeugen
			if (bSecure) textBox.UseSystemPasswordChar = true;
		  textBox.Text = sValue;
		  textBox.SetBounds(12, label.Bottom, label.Right - 12, 20);

		  // Buttons erzeugen
		  buttonOk.Text = "OK";
		  buttonCancel.Text = "Abbrechen";
		  buttonOk.DialogResult = DialogResult.OK;
		  buttonCancel.DialogResult = DialogResult.Cancel;
		  buttonOk.SetBounds(System.Math.Max(12, label.Right - 158), label.Bottom + 36, 75, 23);
		  buttonCancel.SetBounds(System.Math.Max(93, label.Right - 77), label.Bottom + 36, 75, 23);

		  // configure form
			if (string.IsNullOrEmpty(sTitle))
				form.Text = System.AppDomain.CurrentDomain.FriendlyName;
			else
				form.Text = sTitle;
			form.ClientSize = new System.Drawing.Size(System.Math.Max(178, label.Right + 10), label.Bottom + 71);
		  form.Controls.AddRange(new Control[] { textBox, buttonOk, buttonCancel });
		  form.FormBorderStyle = FormBorderStyle.FixedDialog;
		  form.StartPosition = FormStartPosition.CenterScreen;
		  form.MinimizeBox = false;
		  form.MaximizeBox = false;
		  form.AcceptButton = buttonOk;
		  form.CancelButton = buttonCancel;

		  // show and compute form
		  DialogResult dialogResult = form.ShowDialog();
		  sValue = textBox.Text;
		  return dialogResult;
		}

		public static DialogResult Show(string sTitle, string sPrompt, ref string sValue)
		{
			return Show(sTitle, sPrompt, ref sValue, false);
		}
	}

	public class ChoiceBox
	{
		public static int Show(System.Collections.ObjectModel.Collection<ChoiceDescription> aAuswahl, int iVorgabe, string sTitle, string sPrompt)
		{
		  // bei leerem Array abbrechen
		  if (aAuswahl == null) return -1;
		  if (aAuswahl.Count < 1) return -1;

		  // Controls erzeugen
		  Form form = new Form();
	    RadioButton[] aradioButton = new RadioButton[aAuswahl.Count];
	    ToolTip toolTip = new ToolTip();
		  Button buttonOk = new Button();

		  // Am Label orientieren sich die Größen und Positionen
		  // Dieses Control also zuerst fertigstellen, wenn ein Prompt vorhanden
		  int iPosY = 19, iMaxX = 0;
			if (!string.IsNullOrEmpty(sPrompt))
			{
		  	Label label = new Label();
			  label.Text = sPrompt;
		  	label.Location = new Point(9, 19);
		  	label.AutoSize = true;
		  	// erst durch Add() wird die Größe des Labels ermittelt
		  	form.Controls.Add(label);
		  	iPosY = label.Bottom;
		  	iMaxX = label.Right;
			}

		  // An den Radiobuttons orientieren sich die weiteren Größen und Positionen
		  // Diese Controls also jetzt fertigstellen
		  int Counter = 0;
		  foreach (ChoiceDescription sAuswahl in aAuswahl)
		  {
				aradioButton[Counter] = new RadioButton();
				aradioButton[Counter].Text = sAuswahl.Label;
				if (Counter == iVorgabe)
	    	{ aradioButton[Counter].Checked = true; }
		  	aradioButton[Counter].Location = new Point(9, iPosY);
		  	aradioButton[Counter].AutoSize = true;
		  	// erst durch Add() wird die Größe des Labels ermittelt
		  	form.Controls.Add(aradioButton[Counter]);
		  	iPosY = aradioButton[Counter].Bottom;
		  	if (aradioButton[Counter].Right > iMaxX) { iMaxX = aradioButton[Counter].Right; }
		  	if (!string.IsNullOrEmpty(sAuswahl.HelpMessage))
		  	{
		  		 toolTip.SetToolTip(aradioButton[Counter], sAuswahl.HelpMessage);
		  	}
		  	Counter++;
		  }

			// Tooltip auch anzeigen, wenn Parent-Fenster inaktiv ist
			toolTip.ShowAlways = true;

		  // Button erzeugen
		  buttonOk.Text = "OK";
		  buttonOk.DialogResult = DialogResult.OK;
		  buttonOk.SetBounds(System.Math.Max(12, iMaxX - 77), iPosY + 36, 75, 23);

		  // configure form
			if (string.IsNullOrEmpty(sTitle))
				form.Text = System.AppDomain.CurrentDomain.FriendlyName;
			else
				form.Text = sTitle;
			form.ClientSize = new System.Drawing.Size(System.Math.Max(178, iMaxX + 10), iPosY + 71);
		  form.Controls.Add(buttonOk);
		  form.FormBorderStyle = FormBorderStyle.FixedDialog;
		  form.StartPosition = FormStartPosition.CenterScreen;
		  form.MinimizeBox = false;
		  form.MaximizeBox = false;
		  form.AcceptButton = buttonOk;

		  // show and compute form
		  if (form.ShowDialog() == DialogResult.OK)
		  { int iRueck = -1;
		  	for (Counter = 0; Counter < aAuswahl.Count; Counter++)
		  	{
	    		if (aradioButton[Counter].Checked == true)
	    		{ iRueck = Counter; }
		  	}
	    	return iRueck;
		  }
		  else
		  	return -1;
		}
	}

	public class ReadKeyBox
	{
		[DllImport("user32.dll")]
		public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpKeyState,
			[Out, MarshalAs(UnmanagedType.LPWStr, SizeConst = 64)] System.Text.StringBuilder pwszBuff,
			int cchBuff, uint wFlags);

		static string GetCharFromKeys(Keys keys, bool bShift, bool bAltGr)
		{
			System.Text.StringBuilder buffer = new System.Text.StringBuilder(64);
			byte[] keyboardState = new byte[256];
			if (bShift)
			{ keyboardState[(int) Keys.ShiftKey] = 0xff; }
			if (bAltGr)
			{ keyboardState[(int) Keys.ControlKey] = 0xff;
				keyboardState[(int) Keys.Menu] = 0xff;
			}
			if (ToUnicode((uint) keys, 0, keyboardState, buffer, 64, 0) >= 1)
				return buffer.ToString();
			else
				return "\0";
		}

		class KeyboardForm : Form
		{
			public KeyboardForm()
			{
				this.KeyDown += new KeyEventHandler(KeyboardForm_KeyDown);
				this.KeyUp += new KeyEventHandler(KeyboardForm_KeyUp);
			}

			// check for KeyDown or KeyUp?
			public bool checkKeyDown = true;
			// key code for pressed key
			public KeyInfo keyinfo;

			void KeyboardForm_KeyDown(object sender, KeyEventArgs e)
			{
				if (checkKeyDown)
				{ // store key info
					keyinfo.VirtualKeyCode = e.KeyValue;
					keyinfo.Character = GetCharFromKeys(e.KeyCode, e.Shift, e.Alt & e.Control)[0];
					keyinfo.KeyDown = false;
			    keyinfo.ControlKeyState = 0;
			    if (e.Alt) { keyinfo.ControlKeyState = ControlKeyStates.LeftAltPressed | ControlKeyStates.RightAltPressed; }
			    if (e.Control)
			    { keyinfo.ControlKeyState |= ControlKeyStates.LeftCtrlPressed | ControlKeyStates.RightCtrlPressed;
			    	if (!e.Alt)
			    	{ if (e.KeyValue > 64 && e.KeyValue < 96) keyinfo.Character = (char)(e.KeyValue - 64); }
			    }
			    if (e.Shift) { keyinfo.ControlKeyState |= ControlKeyStates.ShiftPressed; }
			    if ((e.Modifiers & System.Windows.Forms.Keys.CapsLock) > 0) { keyinfo.ControlKeyState |= ControlKeyStates.CapsLockOn; }
			    if ((e.Modifiers & System.Windows.Forms.Keys.NumLock) > 0) { keyinfo.ControlKeyState |= ControlKeyStates.NumLockOn; }
					// and close the form
					this.Close();
				}
			}

			void KeyboardForm_KeyUp(object sender, KeyEventArgs e)
			{
				if (!checkKeyDown)
				{ // store key info
					keyinfo.VirtualKeyCode = e.KeyValue;
					keyinfo.Character = GetCharFromKeys(e.KeyCode, e.Shift, e.Alt & e.Control)[0];
					keyinfo.KeyDown = true;
			    keyinfo.ControlKeyState = 0;
			    if (e.Alt) { keyinfo.ControlKeyState = ControlKeyStates.LeftAltPressed | ControlKeyStates.RightAltPressed; }
			    if (e.Control)
			    { keyinfo.ControlKeyState |= ControlKeyStates.LeftCtrlPressed | ControlKeyStates.RightCtrlPressed;
			    	if (!e.Alt)
			    	{ if (e.KeyValue > 64 && e.KeyValue < 96) keyinfo.Character = (char)(e.KeyValue - 64); }
			    }
			    if (e.Shift) { keyinfo.ControlKeyState |= ControlKeyStates.ShiftPressed; }
			    if ((e.Modifiers & System.Windows.Forms.Keys.CapsLock) > 0) { keyinfo.ControlKeyState |= ControlKeyStates.CapsLockOn; }
			    if ((e.Modifiers & System.Windows.Forms.Keys.NumLock) > 0) { keyinfo.ControlKeyState |= ControlKeyStates.NumLockOn; }
					// and close the form
					this.Close();
				}
			}
		}

		public static KeyInfo Show(string sTitle, string sPrompt, bool bIncludeKeyDown)
		{
			// Controls erzeugen
			KeyboardForm form = new KeyboardForm();
			Label label = new Label();

			// Am Label orientieren sich die Größen und Positionen
			// Dieses Control also zuerst fertigstellen
			if (string.IsNullOrEmpty(sPrompt))
			{
					label.Text = "Press a key";
			}
			else
				label.Text = sPrompt;
			label.Location = new Point(9, 19);
			label.AutoSize = true;
			// erst durch Add() wird die Größe des Labels ermittelt
			form.Controls.Add(label);

			// configure form
			if (string.IsNullOrEmpty(sTitle))
				form.Text = System.AppDomain.CurrentDomain.FriendlyName;
			else
				form.Text = sTitle;
			form.ClientSize = new System.Drawing.Size(System.Math.Max(178, label.Right + 10), label.Bottom + 55);
			form.FormBorderStyle = FormBorderStyle.FixedDialog;
			form.StartPosition = FormStartPosition.CenterScreen;
			form.MinimizeBox = false;
			form.MaximizeBox = false;

			// show and compute form
			form.checkKeyDown = bIncludeKeyDown;
			form.ShowDialog();
			return form.keyinfo;
		}
	}

"@ })

	internal class PS2EXEHostUI : PSHostUserInterface
	{

		private PS2EXEHostRawUI rawUI = null;

		public PS2EXEHostUI() : base()
		{
			rawUI = new PS2EXEHostRawUI();
$(if (!$noConsole) {@"
			rawUI.ForegroundColor = Console.ForegroundColor;
			rawUI.BackgroundColor = Console.BackgroundColor;
"@ })
		}

		public override Dictionary<string, PSObject> Prompt(string caption, string message, System.Collections.ObjectModel.Collection<FieldDescription> descriptions)
		{
$(if (!$noConsole) {@"
			if (!string.IsNullOrEmpty(caption)) WriteLine(caption);
			if (!string.IsNullOrEmpty(message)) WriteLine(message);
"@ } else {@"
			if ((!string.IsNullOrEmpty(caption)) || (!string.IsNullOrEmpty(message)))
			{ string sTitel = System.AppDomain.CurrentDomain.FriendlyName, sMeldung = "";

				if (!string.IsNullOrEmpty(caption)) sTitel = caption;
				if (!string.IsNullOrEmpty(message)) sMeldung = message;
				MessageBox.Show(sMeldung, sTitel);
			}

			// Titel und Labeltext für Inputbox zurücksetzen
			ibcaption = "";
			ibmessage = "";
"@ })
			Dictionary<string, PSObject> ret = new Dictionary<string, PSObject>();
			foreach (FieldDescription cd in descriptions)
			{
				Type t = null;
				if (string.IsNullOrEmpty(cd.ParameterAssemblyFullName))
					t = typeof(string);
				else
					t = Type.GetType(cd.ParameterAssemblyFullName);

				if (t.IsArray)
				{
					Type elementType = t.GetElementType();
					Type genericListType = Type.GetType("System.Collections.Generic.List"+((char)0x60).ToString()+"1");
					genericListType = genericListType.MakeGenericType(new Type[] { elementType });
					ConstructorInfo constructor = genericListType.GetConstructor(BindingFlags.CreateInstance | BindingFlags.Instance | BindingFlags.Public, null, Type.EmptyTypes, null);
					object resultList = constructor.Invoke(null);

					int index = 0;
					string data = "";
					do
					{
						try
						{
$(if (!$noConsole) {@"
							if (!string.IsNullOrEmpty(cd.Name)) Write(string.Format("{0}[{1}]: ", cd.Name, index));
"@ } else {@"
							if (!string.IsNullOrEmpty(cd.Name)) ibmessage = string.Format("{0}[{1}]: ", cd.Name, index);
"@ })
							data = ReadLine();
							if (string.IsNullOrEmpty(data))
								break;

							object o = System.Convert.ChangeType(data, elementType);
							genericListType.InvokeMember("Add", BindingFlags.InvokeMethod | BindingFlags.Public | BindingFlags.Instance, null, resultList, new object[] { o });
						}
						catch
						{
							throw new Exception("Exception in ik.PowerShell.PS2EXEHostUI.Prompt*1");
						}
						index++;
					} while (true);

					System.Array retArray = (System.Array )genericListType.InvokeMember("ToArray", BindingFlags.InvokeMethod | BindingFlags.Public | BindingFlags.Instance, null, resultList, null);
					ret.Add(cd.Name, new PSObject(retArray));
				}
				else
				{
					object o = null;
					string l = null;
					try
					{
						if (t != typeof(System.Security.SecureString))
						{
							if (t != typeof(System.Management.Automation.PSCredential))
							{
$(if (!$noConsole) {@"
								if (!string.IsNullOrEmpty(cd.Name)) Write(cd.Name);
								if (!string.IsNullOrEmpty(cd.HelpMessage)) Write(" (Type !? for help.)");
								if ((!string.IsNullOrEmpty(cd.Name)) || (!string.IsNullOrEmpty(cd.HelpMessage))) Write(": ");
"@ } else {@"
								if (!string.IsNullOrEmpty(cd.Name)) ibmessage = string.Format("{0}: ", cd.Name);
								if (!string.IsNullOrEmpty(cd.HelpMessage)) ibmessage += "\n(Type !? for help.)";
"@ })
								do {
									l = ReadLine();
									if (l == "!?")
										WriteLine(cd.HelpMessage);
									else
									{
										if (string.IsNullOrEmpty(l)) o = cd.DefaultValue;
										if (o == null)
										{
											try {
												o = System.Convert.ChangeType(l, t);
											}
											catch {
												Write("Wrong format, please repeat input: ");
												l = "!?";
											}
										}
									}
								} while (l == "!?");
							}
							else
							{
								PSCredential pscred = PromptForCredential("", "", "", "");
								o = pscred;
							}
						}
						else
						{
$(if (!$noConsole) {@"
								if (!string.IsNullOrEmpty(cd.Name)) Write(string.Format("{0}: ", cd.Name));
"@ } else {@"
								if (!string.IsNullOrEmpty(cd.Name)) ibmessage = string.Format("{0}: ", cd.Name);
"@ })

							SecureString pwd = null;
							pwd = ReadLineAsSecureString();
							o = pwd;
						}

						ret.Add(cd.Name, new PSObject(o));
					}
					catch
					{
						throw new Exception("Exception in ik.PowerShell.PS2EXEHostUI.Prompt*2");
					}
				}
			}
$(if ($noConsole) {@"
			// Titel und Labeltext für Inputbox zurücksetzen
			ibcaption = "";
			ibmessage = "";
"@ })
			return ret;
		}

		public override int PromptForChoice(string caption, string message, System.Collections.ObjectModel.Collection<ChoiceDescription> choices, int defaultChoice)
		{
$(if ($noConsole) {@"
			int iReturn = ChoiceBox.Show(choices, defaultChoice, caption, message);
			if (iReturn == -1) { iReturn = defaultChoice; }
			return iReturn;
"@ } else {@"
			if (!string.IsNullOrEmpty(caption))
				WriteLine(caption);
			WriteLine(message);
			int idx = 0;
			SortedList<string, int> res = new SortedList<string, int>();
			foreach (ChoiceDescription cd in choices)
			{
				string lkey = cd.Label.Substring(0, 1), ltext = cd.Label;
				int pos = cd.Label.IndexOf('&');
				if (pos > -1)
				{
					lkey = cd.Label.Substring(pos + 1, 1).ToUpper();
					if (pos > 0)
						ltext = cd.Label.Substring(0, pos) + cd.Label.Substring(pos + 1);
					else
						ltext = cd.Label.Substring(1);
				}
				res.Add(lkey.ToLower(), idx);

				if (idx > 0) Write("  ");
				if (idx == defaultChoice)
				{
					Write(ConsoleColor.Yellow, Console.BackgroundColor, string.Format("[{0}] {1}", lkey, ltext));
					if (!string.IsNullOrEmpty(cd.HelpMessage))
						Write(ConsoleColor.Gray, Console.BackgroundColor, string.Format(" ({0})", cd.HelpMessage));
				}
				else
				{
					Write(ConsoleColor.Gray, Console.BackgroundColor, string.Format("[{0}] {1}", lkey, ltext));
					if (!string.IsNullOrEmpty(cd.HelpMessage))
						Write(ConsoleColor.Gray, Console.BackgroundColor, string.Format(" ({0})", cd.HelpMessage));
				}
				idx++;
			}
			Write(": ");

			try
			{
				while (true)
				{ string s = Console.ReadLine().ToLower();
					if (res.ContainsKey(s))
						return res[s];
					if (string.IsNullOrEmpty(s))
						return defaultChoice;
				}
			}
			catch { }

			return defaultChoice;
"@ })
		}

		public override PSCredential PromptForCredential(string caption, string message, string userName, string targetName, PSCredentialTypes allowedCredentialTypes, PSCredentialUIOptions options)
		{
$(if (!$noConsole) {@"
			if (!string.IsNullOrEmpty(caption)) WriteLine(caption);
			WriteLine(message);

			string un;
			if ((string.IsNullOrEmpty(userName)) || ((options & PSCredentialUIOptions.ReadOnlyUserName) == 0))
			{
				Write("User name: ");
				un = ReadLine();
			}
			else
			{
				Write("User name: ");
				if (!string.IsNullOrEmpty(targetName)) Write(targetName + "\\");
				WriteLine(userName);
				un = userName;
			}
			SecureString pwd = null;
			Write("Password: ");
			pwd = ReadLineAsSecureString();

			if (string.IsNullOrEmpty(un)) un = "<NOUSER>";
			if (!string.IsNullOrEmpty(targetName))
			{
				if (un.IndexOf('\\') < 0)
					un = targetName + "\\" + un;
			}

			PSCredential c2 = new PSCredential(un, pwd);
			return c2;
"@ } else {@"
			ik.PowerShell.CredentialForm.UserPwd cred = CredentialForm.PromptForPassword(caption, message, targetName, userName, allowedCredentialTypes, options);
			if (cred != null)
			{
				System.Security.SecureString x = new System.Security.SecureString();
				foreach (char c in cred.Password.ToCharArray())
					x.AppendChar(c);

				return new PSCredential(cred.User, x);
			}
			return new PSCredential("<NOUSER>", new System.Security.SecureString());
"@ })
		}

		public override PSCredential PromptForCredential(string caption, string message, string userName, string targetName)
		{
$(if (!$noConsole) {@"
			if (!string.IsNullOrEmpty(caption)) WriteLine(caption);
			WriteLine(message);

			string un;
			if (string.IsNullOrEmpty(userName))
			{
				Write("User name: ");
				un = ReadLine();
			}
			else
			{
				Write("User name: ");
				if (!string.IsNullOrEmpty(targetName)) Write(targetName + "\\");
				WriteLine(userName);
				un = userName;
			}
			SecureString pwd = null;
			Write("Password: ");
			pwd = ReadLineAsSecureString();

			if (string.IsNullOrEmpty(un)) un = "<NOUSER>";
			if (!string.IsNullOrEmpty(targetName))
			{
				if (un.IndexOf('\\') < 0)
					un = targetName + "\\" + un;
			}

			PSCredential c2 = new PSCredential(un, pwd);
			return c2;
"@ } else {@"
			ik.PowerShell.CredentialForm.UserPwd cred = CredentialForm.PromptForPassword(caption, message, targetName, userName, PSCredentialTypes.Default, PSCredentialUIOptions.Default);
			if (cred != null)
			{
				System.Security.SecureString x = new System.Security.SecureString();
				foreach (char c in cred.Password.ToCharArray())
					x.AppendChar(c);

				return new PSCredential(cred.User, x);
			}
			return new PSCredential("<NOUSER>", new System.Security.SecureString());
"@ })
		}

		public override PSHostRawUserInterface RawUI
		{
			get
			{
				return rawUI;
			}
		}

$(if ($noConsole) {@"
		private string ibcaption;
		private string ibmessage;
"@ })

		public override string ReadLine()
		{
$(if (!$noConsole) {@"
			return Console.ReadLine();
"@ } else {@"
			string sWert = "";
			if (InputBox.Show(ibcaption, ibmessage, ref sWert) == DialogResult.OK)
				return sWert;
			else
				return "";
"@ })
		}

		private System.Security.SecureString getPassword()
		{
			System.Security.SecureString pwd = new System.Security.SecureString();
			while (true)
			{
				ConsoleKeyInfo i = Console.ReadKey(true);
				if (i.Key == ConsoleKey.Enter)
				{
					Console.WriteLine();
					break;
				}
				else if (i.Key == ConsoleKey.Backspace)
				{
					if (pwd.Length > 0)
					{
						pwd.RemoveAt(pwd.Length - 1);
						Console.Write("\b \b");
					}
				}
				else
				{
					pwd.AppendChar(i.KeyChar);
					Console.Write("*");
				}
			}
			return pwd;
		}

		public override System.Security.SecureString ReadLineAsSecureString()
		{
			System.Security.SecureString secstr = new System.Security.SecureString();
$(if (!$noConsole) {@"
			secstr = getPassword();
"@ } else {@"
			string sWert = "";

			if (InputBox.Show("", "", ref sWert, true) == DialogResult.OK)
			{
				foreach (char ch in sWert)
					secstr.AppendChar(ch);
			}
"@ })
			return secstr;
		}

		// called by Write-Host
		public override void Write(ConsoleColor foregroundColor, ConsoleColor backgroundColor, string value)
		{
$(if (!$noConsole) {@"
			ConsoleColor fgc = Console.ForegroundColor, bgc = Console.BackgroundColor;
			Console.ForegroundColor = foregroundColor;
			Console.BackgroundColor = backgroundColor;
			Console.Write(value);
			Console.ForegroundColor = fgc;
			Console.BackgroundColor = bgc;
"@ } else {@"
			if ((!string.IsNullOrEmpty(value)) && (value != "\n"))
				MessageBox.Show(value, System.AppDomain.CurrentDomain.FriendlyName);
"@ })
		}

		public override void Write(string value)
		{
$(if (!$noConsole) {@"
			Console.Write(value);
"@ } else {@"
			if ((!string.IsNullOrEmpty(value)) && (value != "\n"))
				MessageBox.Show(value, System.AppDomain.CurrentDomain.FriendlyName);
"@ })
		}

		// called by Write-Debug
		public override void WriteDebugLine(string message)
		{
$(if (!$noConsole) {@"
			ConsoleColor fgc = Console.ForegroundColor, bgc = Console.BackgroundColor;
			Console.ForegroundColor = ConsoleColor.Cyan;
			Console.BackgroundColor = ConsoleColor.Black;
			Console.WriteLine(string.Format("DEBUG: {0}", message));
			Console.ForegroundColor = fgc;
			Console.BackgroundColor = bgc;
"@ } else {@"
			MessageBox.Show(message, System.AppDomain.CurrentDomain.FriendlyName, MessageBoxButtons.OK, MessageBoxIcon.Information);
"@ })
		}

		// called by Write-Error
		public override void WriteErrorLine(string value)
		{
$(if (!$noConsole) {@"
			ConsoleColor fgc = Console.ForegroundColor, bgc = Console.BackgroundColor;
			Console.ForegroundColor = ConsoleColor.Red;
			Console.BackgroundColor = ConsoleColor.Black;
			Console.WriteLine(string.Format("ERROR: {0}", value));
			Console.ForegroundColor = fgc;
			Console.BackgroundColor = bgc;
"@ } else {@"
			MessageBox.Show(value, System.AppDomain.CurrentDomain.FriendlyName, MessageBoxButtons.OK, MessageBoxIcon.Error);
"@ })
		}

		public override void WriteLine()
		{
$(if (!$noConsole) {@"
			Console.WriteLine();
"@ } else {@"
			MessageBox.Show("", System.AppDomain.CurrentDomain.FriendlyName);
"@ })
		}

		public override void WriteLine(ConsoleColor foregroundColor, ConsoleColor backgroundColor, string value)
		{
$(if (!$noConsole) {@"
			ConsoleColor fgc = Console.ForegroundColor, bgc = Console.BackgroundColor;
			Console.ForegroundColor = foregroundColor;
			Console.BackgroundColor = backgroundColor;
			Console.WriteLine(value);
			Console.ForegroundColor = fgc;
			Console.BackgroundColor = bgc;
"@ } else {@"
			if ((!string.IsNullOrEmpty(value)) && (value != "\n"))
				MessageBox.Show(value, System.AppDomain.CurrentDomain.FriendlyName);
"@ })
		}

		// called by Write-Output
		public override void WriteLine(string value)
		{
$(if (!$noConsole) {@"
			Console.WriteLine(value);
"@ } else {@"
			if ((!string.IsNullOrEmpty(value)) && (value != "\n"))
				MessageBox.Show(value, System.AppDomain.CurrentDomain.FriendlyName);
"@ })
		}

		public override void WriteProgress(long sourceId, ProgressRecord record)
		{

		}

		// called by Write-Verbose
		public override void WriteVerboseLine(string message)
		{
$(if (!$noConsole) {@"
			ConsoleColor fgc = Console.ForegroundColor, bgc = Console.BackgroundColor;
			Console.ForegroundColor = ConsoleColor.Yellow;
			Console.BackgroundColor = ConsoleColor.Black;
			Console.WriteLine(string.Format("VERBOSE: {0}", message));
			Console.ForegroundColor = fgc;
			Console.BackgroundColor = bgc;
"@ } else {@"
			MessageBox.Show(message, System.AppDomain.CurrentDomain.FriendlyName, MessageBoxButtons.OK, MessageBoxIcon.Information);
"@ })
		}

		// called by Write-Warning
		public override void WriteWarningLine(string message)
		{
$(if (!$noConsole) {@"
			ConsoleColor fgc = Console.ForegroundColor, bgc = Console.BackgroundColor;
			Console.ForegroundColor = ConsoleColor.Magenta;
			Console.BackgroundColor = ConsoleColor.Black;
			Console.WriteLine(string.Format("WARNING: {0}", message));
			Console.ForegroundColor = fgc;
			Console.BackgroundColor = bgc;
"@ } else {@"
			MessageBox.Show(message, System.AppDomain.CurrentDomain.FriendlyName, MessageBoxButtons.OK, MessageBoxIcon.Warning);
"@ })
		}
	}

 	internal class PS2EXEHost : PSHost
	{
		private PS2EXEApp parent;
		private PS2EXEHostUI ui = null;

		private CultureInfo originalCultureInfo = System.Threading.Thread.CurrentThread.CurrentCulture;

		private CultureInfo originalUICultureInfo = System.Threading.Thread.CurrentThread.CurrentUICulture;

		private Guid myId = Guid.NewGuid();

		public PS2EXEHost(PS2EXEApp app, PS2EXEHostUI ui)
		{
			this.parent = app;
			this.ui = ui;
		}

		public override System.Globalization.CultureInfo CurrentCulture
		{
			get
			{
				return this.originalCultureInfo;
			}
		}

		public override System.Globalization.CultureInfo CurrentUICulture
		{
			get
			{
				return this.originalUICultureInfo;
			}
		}

		public override Guid InstanceId
		{
			get
			{
				return this.myId;
			}
		}

		public override string Name
		{
			get
			{
				return "PS2EXE_Host";
			}
		}

		public override PSHostUserInterface UI
		{
			get
			{
				return ui;
			}
		}

		public override Version Version
		{
			get
			{
				return new Version(0, 5, 0, 0);
			}
		}

		public override void EnterNestedPrompt()
		{
		}

		public override void ExitNestedPrompt()
		{
		}

		public override void NotifyBeginApplication()
		{
			return;
		}

		public override void NotifyEndApplication()
		{
			return;
		}

		public override void SetShouldExit(int exitCode)
		{
			this.parent.ShouldExit = true;
			this.parent.ExitCode = exitCode;
		}
	}

	internal interface PS2EXEApp
	{
		bool ShouldExit { get; set; }
		int ExitCode { get; set; }
	}

	internal class PS2EXE : PS2EXEApp
	{
		private bool shouldExit;

		private int exitCode;

		public bool ShouldExit
		{
			get { return this.shouldExit; }
			set { this.shouldExit = value; }
		}

		public int ExitCode
		{
			get { return this.exitCode; }
			set { this.exitCode = value; }
		}

		$(if ($Sta){"[STAThread]"})$(if ($Mta){"[MTAThread]"})
		private static int Main(string[] args)
		{
			$culture

			PS2EXE me = new PS2EXE();

			bool paramWait = false;
			string extractFN = string.Empty;

			PS2EXEHostUI ui = new PS2EXEHostUI();
			PS2EXEHost host = new PS2EXEHost(me, ui);
			System.Threading.ManualResetEvent mre = new System.Threading.ManualResetEvent(false);

			AppDomain.CurrentDomain.UnhandledException += new UnhandledExceptionEventHandler(CurrentDomain_UnhandledException);

			try
			{
				using (Runspace myRunSpace = RunspaceFactory.CreateRunspace(host))
				{
					$(if ($Sta -or $Mta) {"myRunSpace.ApartmentState = System.Threading.ApartmentState."})$(if ($Sta){"STA"})$(if ($Mta){"MTA"});
					myRunSpace.Open();

					using (System.Management.Automation.PowerShell powershell = System.Management.Automation.PowerShell.Create())
					{
$(if (!$noConsole) {@"
						Console.CancelKeyPress += new ConsoleCancelEventHandler(delegate(object sender, ConsoleCancelEventArgs e)
						{
							try
							{
								powershell.BeginStop(new AsyncCallback(delegate(IAsyncResult r)
								{
									mre.Set();
									e.Cancel = true;
								}), null);
							}
							catch
							{
							};
						});
"@ })

						powershell.Runspace = myRunSpace;
						powershell.Streams.Error.DataAdded += new EventHandler<DataAddedEventArgs>(delegate(object sender, DataAddedEventArgs e)
						{
							ui.WriteErrorLine(((PSDataCollection<ErrorRecord>)sender)[e.Index].ToString());
						});

						PSDataCollection<PSObject> inp = new PSDataCollection<PSObject>();
						inp.DataAdded += new EventHandler<DataAddedEventArgs>(delegate(object sender, DataAddedEventArgs e)
						{
							ui.WriteLine(inp[e.Index].ToString());
						});

						PSDataCollection<PSObject> outp = new PSDataCollection<PSObject>();
						outp.DataAdded += new EventHandler<DataAddedEventArgs>(delegate(object sender, DataAddedEventArgs e)
						{
							ui.WriteLine(outp[e.Index].ToString());
						});

						int separator = 0;
						int idx = 0;
						foreach (string s in args)
						{
							if (string.Compare(s, "-wait", true) == 0)
								paramWait = true;
							else if (s.StartsWith("-extract", StringComparison.InvariantCultureIgnoreCase))
							{
								string[] s1 = s.Split(new string[] { ":" }, 2, StringSplitOptions.RemoveEmptyEntries);
								if (s1.Length != 2)
								{
									Console.WriteLine("If you specify the -extract option you need to add a file for extraction in this way\r\n   -extract:\"<filename>\"");
									return 1;
								}
								extractFN = s1[1].Trim(new char[] { '\"' });
							}
							else if (string.Compare(s, "-end", true) == 0)
							{
								separator = idx + 1;
								break;
							}
							else if (string.Compare(s, "-debug", true) == 0)
							{
								System.Diagnostics.Debugger.Launch();
								break;
							}
							idx++;
						}

						string script = System.Text.Encoding.UTF8.GetString(System.Convert.FromBase64String(@"$($script)"));

						if (!string.IsNullOrEmpty(extractFN))
						{
							System.IO.File.WriteAllText(extractFN, script);
							return 0;
						}

						powershell.AddScript(script);

      			// parse parameters
      			string argbuffer = null;
      			// regex for named parameters
      			System.Text.RegularExpressions.Regex regex = new System.Text.RegularExpressions.Regex("^(?:/|-)([^/-: ]+)(?::?)([^:]*)$");

      			for (int i = separator; i < args.Length; i++)
      			{
      				System.Text.RegularExpressions.Match match = regex.Match(args[i]);
        			if (match.Success && match.Groups.Count == 3)
              { // parameter in powershell style, means named parameter found
                if (argbuffer != null) // already a named parameter in buffer, then flush it
                	powershell.AddParameter(argbuffer);

                if (match.Groups[2].Value.Trim() == "")
                { // store named parameter in buffer
                	argbuffer = match.Groups[1].Value;
                }
                else
                 	// caution: when called in powershell $TRUE gets converted, when called in cmd.exe not
                 	if ((match.Groups[2].Value == "$TRUE") || (match.Groups[2].Value.ToUpper() == "\x24TRUE")) 
                	{ // switch found
                  	powershell.AddParameter(match.Groups[1].Value, true);
                    argbuffer = null;
                  }
                  else
                 		// caution: when called in powershell $FALSE gets converted, when called in cmd.exe not
                   	if ((match.Groups[2].Value == "$FALSE") || (match.Groups[2].Value.ToUpper() == "\x24"+"FALSE"))
                    { // switch found
                    	powershell.AddParameter(match.Groups[1].Value, false);
                      argbuffer = null;
                    }
                    else
                    { // named parameter with value found
                      powershell.AddParameter(match.Groups[1].Value, match.Groups[2].Value);
                      argbuffer = null;
                    }
              }
              else
              { // unnamed parameter found
                if (argbuffer != null)
                { // already a named parameter in buffer, so this is the value
                	powershell.AddParameter(argbuffer, args[i]);
                  argbuffer = null;
                }
                else
                { // position parameter found
                	powershell.AddArgument(args[i]);
                }
              }
            }

            if (argbuffer != null) powershell.AddParameter(argbuffer); // Parameterpuffer flushen...

						// convert output to strings
						powershell.AddCommand("out-string");
						// with a single string per line
						powershell.AddParameter("-stream");

						powershell.BeginInvoke<PSObject, PSObject>(inp, outp, null, new AsyncCallback(delegate(IAsyncResult ar)
						{
							if (ar.IsCompleted)
								mre.Set();
						}), null);

						while (!me.ShouldExit && !mre.WaitOne(100))
						{ };

						powershell.Stop();
					}

					myRunSpace.Close();
				}
			}
			catch (Exception ex)
			{
$(if (!$noConsole) {@"
				Console.Write("An exception occured: ");
				Console.WriteLine(ex.Message);
"@ } else {@"
				MessageBox.Show("An exception occured: " + ex.Message, System.AppDomain.CurrentDomain.FriendlyName, MessageBoxButtons.OK, MessageBoxIcon.Error);
"@ })
			}

			if (paramWait)
			{
$(if (!$noConsole) {@"
				Console.WriteLine("Hit any key to exit...");
				Console.ReadKey();
"@ } else {@"
				MessageBox.Show("Click OK to exit...", System.AppDomain.CurrentDomain.FriendlyName);
"@ })
			}
			return me.ExitCode;
		}

		static void CurrentDomain_UnhandledException(object sender, UnhandledExceptionEventArgs e)
		{
			throw new Exception("Unhandeled exception in PS2EXE");
		}
	}
}
"@
#endregion

#region EXE Config file
	$configFileForEXE2 = "<?xml version=""1.0"" encoding=""utf-8"" ?>`r`n<configuration><startup><supportedRuntime version=""v2.0.50727""/></startup></configuration>"
	$configFileForEXE3 = "<?xml version=""1.0"" encoding=""utf-8"" ?>`r`n<configuration><startup><supportedRuntime version=""v4.0"" sku="".NETFramework,Version=v4.0"" /></startup></configuration>"
#endregion

Write-Host "Compiling file... " -NoNewline
$cr = $cop.CompileAssemblyFromSource($cp, $programFrame)
if ($cr.Errors.Count -gt 0)
{
	Write-Host ""
	Write-Host ""
	if (Test-Path $outputFile)
	{
		Remove-Item $outputFile -Verbose:$FALSE
	}
	Write-Host -ForegroundColor red "Could not create the PowerShell .exe file because of compilation errors. Use -verbose parameter to see details."
	$cr.Errors | % { Write-Verbose $_ -Verbose:$verbose}
}
else
{
	Write-Host ""
	Write-Host ""
	if (Test-Path $outputFile)
	{
		Write-Host "Output file " -NoNewline
		Write-Host $outputFile -NoNewline
		Write-Host " written"

		if ($debug)
		{
			$cr.TempFiles | ? { $_ -ilike "*.cs" } | select -first 1 | % {
				$dstSrc = ([System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($outputFile), [System.IO.Path]::GetFileNameWithoutExtension($outputFile)+".cs"))
				Write-Host "Source file name for debug copied: $($dstSrc)"
				Copy-Item -Path $_ -Destination $dstSrc -Force
			}
			$cr.TempFiles | Remove-Item -Verbose:$FALSE -Force -ErrorAction SilentlyContinue
		}
		if ($runtime20)
		{
			$configFileForEXE2 | Set-Content ($outputFile+".config")
			Write-Host "Config file for EXE created."
		}
		if ($runtime30 -or $runtime40)
		{
			$configFileForEXE3 | Set-Content ($outputFile+".config")
			Write-Host "Config file for EXE created."
		}
	}
	else
	{
		Write-Host "Output file " -NoNewline -ForegroundColor Red
		Write-Host $outputFile -ForegroundColor Red -NoNewline
		Write-Host " not written" -ForegroundColor Red
	}
}
