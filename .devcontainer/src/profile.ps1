$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
function Prompt {
    if ((Get-History).Count -gt 0) {
        $executionTime = ((Get-History)[-1].EndExecutionTime - (Get-History)[-1].StartExecutionTime).Totalmilliseconds
    } else { $executionTime = 0 }
    $promptPath = Split-Path $PWD -LeafBase
    [System.Console]::WriteLine(
        "`e[93m[`e[38;5;147m{0:N1}ms`e[93m] `e[1m`e[34m{1}`e[0m{2}", $executionTime, $promptPath, (Write-VcsStatus)
    )
    return ("`e[92m`u{25BA}`e[0m" * ($nestedPromptLevel + 1)) + ' '
}
if ($IsLinux) {
    Set-Alias -Name '.venv/bin/activate' -Value '.venv/bin/Activate.ps1'
}
$init = [IO.Path]::Combine('.vscode', 'init.ps1')
if (Test-Path $init) {
    & $init
}
Clear-Host
Write-Output ('PowerShell ' + $PSVersionTable.PSVersion.ToString())
Write-Output ('BootUp: ' + (Get-Uptime -Since).ToString() + ' | Uptime: ' + (Get-Uptime).ToString())
