<#
.Description
Creates new context menu item
.Example
.vscode\settings\vscContextMenu.ps1
#>
$ProgramName = 'Code'
$ProgramPath = ($env:Path -split (';') | Select-String -Pattern 'Code\\bin') -replace ('bin', 'Code.exe')
$ErrorActionPreference = 'Stop'

# Open files
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

# This will make it appear when you right click ON a folder
$registryPath = "HKLM:\SOFTWARE\Classes\Directory\shell\$programName"
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
    Write-Output ('Directory context menu for "' + $ProgramName + '" already exists')
}
# This will make it appear when you right click INSIDE a folder
$registryPath = "HKLM:\SOFTWARE\Classes\Directory\Background\shell\$programName"
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
    Write-Output ('Background directory context menu for "' + $ProgramName + '" already exists')
}
