<#
.SYNOPSIS
Creates a Shortcut with Windows PowerShell
.LINK
http://powershellblogger.com/2016/01/create-shortcuts-lnk-or-url-files-with-powershell/
https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-shllink/16cb4ca1-9339-4d0c-a68d-bf1d6cc0f943?redirectedfrom=MSDN
.PARAMETER Source
$Source = "$env:SystemRoot\System32\notepad.exe"
.PARAMETER Destination
$Destination = "$env:USERPROFILE\Desktop"
.EXAMPLE
.include\f-lnk-create.ps1
#>

function New-ShellShortcut {
    param(
        [cmdletbinding()]
        [ValidateScript( { Test-Path $_ } )]$Source,
        [ValidateScript( { Test-Path $_ -PathType 'Container' } )]$Destination
    )

    # Create a path to the link
    $lnkPath = Join-Path -Path $Destination -ChildPath "$([System.IO.Path]::GetFileNameWithoutExtension($Source)).lnk"

    # New-Object : Creates an instance of a Microsoft .NET Framework or COM object.
    # -ComObject WScript.Shell: This creates an instance of the COM object that represents the WScript.Shell for invoke CreateShortCut
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($lnkPath)
    $Shortcut.TargetPath = $Source

    # save the Shortcut to the TargetPath
    $Shortcut.Save()

    if ($Elevated) {
        $bytes = [System.IO.File]::ReadAllBytes($lnkPath)
        $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
        [System.IO.File]::WriteAllBytes($lnkPath, $bytes)
    }
    # return path to created link
    $Shortcut.FullName
}
