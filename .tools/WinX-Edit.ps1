<#
.Synopsis
Modify Win+X menu
.LINK
https://www.digitalcitizen.life/how-customize-winx-menu-windows-using-winx-menu-editor?page=1
https://github.com/riverar/hashlnk/blob/master/bin/hashlnk_0.2.0.0.zip
.PARAMETER Source
$Source = "$($env:ProgramFiles)\PowerShell\7\pwsh.exe"
.EXAMPLE

#>

param (
    [cmdletbinding()]
    [ValidateScript( { Test-Path $_ -PathType 'Leaf' } )]$Source,
    $DestinationName,
    [int]$GroupLevel = 3
)

# include function
. '.\.include\f-lnk-create.ps1'

$DestinationName = $DestinationName ?? [System.IO.Path]::GetFileNameWithoutExtension($Source)

# path to hashlnk
$hashLnk = 'F:\usr\hashlnk\hashlnk.exe'

$lnkPath = New-ShellShortcut -Source $Source -Destination ([System.IO.Path]::GetDirectoryName($hashLnk))

& $hashLnk $lnkPath
& $hashLnk "C:\Users\szymo\AppData\Local\Microsoft\Windows\WinX\Group4\Sound.lnk"

"$($env:LOCALAPPDATA)\Microsoft\Windows\WinX"
taskkill.exe /F /IM explorer.exe; Start-Process explorer.exe
