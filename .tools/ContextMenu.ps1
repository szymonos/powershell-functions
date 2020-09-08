<#
.Description
Creates new context menu item
.Example
C:\Source\Git\DevOps\.tools\ContextMenu.ps1
C:\Source\Git\DevOps\.tools\ContextMenu.ps1 -ProgramName 'Notepad++' -ProgramPath 'F:\usr\Notepad++\notepad++.exe'
#>
param (
    [string]$ProgramName = 'Notepad++',
    [string]$ProgramPath = 'F:\usr\Notepad++\notepad++.exe'
)
$ErrorActionPreference = 'Stop'
$ErrorView = 'ConciseView'

$registryPath = "HKLM:\SOFTWARE\Classes\*\shell\$programName"
if ($null -eq (Get-Item -LiteralPath $registryPath -ErrorAction SilentlyContinue)) {
    try {
        New-Item $registryPath | Out-Null
        New-ItemProperty -LiteralPath $registryPath -Name '(Default)' -PropertyType 'String' -Value "Open with $programName" | Out-Null
        New-ItemProperty -LiteralPath $registryPath -Name 'Icon' -PropertyType 'String' -Value "$ProgramPath,0" | Out-Null
        New-Item "$registryPath\command" | Out-Null
        New-ItemProperty -LiteralPath "$registryPath\command" -Name '(Default)' -PropertyType 'String' -Value ("""$programPath"" ""%1""") | Out-Null
        Write-Output ('Created context menu for "' + $ProgramName + '"')
    }
    catch {
        Write-Warning ('Failed creating context menu for "' + $ProgramName + '"')
    }
}
else {
    Write-Output ('Context menu for "' + $ProgramName + '" already exists')
}
