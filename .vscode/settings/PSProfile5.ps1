$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
function Prompt {
    filter repl1 { $_ -replace '[c-z]:\\Users\\\w+', '~' }
    filter repl2 { $_ -replace 'Microsoft.PowerShell.Core\\FileSystem::', '' }
    if ((Get-History).Count -gt 0) {
        $executionTime = ((Get-History)[-1].EndExecutionTime - (Get-History)[-1].StartExecutionTime).Totalmilliseconds
    }
    else {
        $executionTime = 0
    }
    $promptPath = $PWD | repl1 | repl2
    [Console]::Write('[')
    [console]::ForegroundColor = 'Cyan'; [Console]::Write('{0:N0}ms' -f $executionTime)
    [console]::ForegroundColor = 'White'; [Console]::Write('] ')
    [console]::ForegroundColor = 'Blue'; [Console]::WriteLine($promptPath)
    [console]::ForegroundColor = 'Green'; [Console]::Write('PS')
    [console]::ForegroundColor = 'White';
    return ('>' * ($nestedPromptLevel + 1)) + ' '
}
function Get-Uptime {
    $LastBoot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $Uptime = (Get-Date) - $LastBoot
    'BootUp: ' + $LastBoot.ToString() + ' | Uptime: ' + $Uptime.Days + ' days, ' + $Uptime.Hours + ' hours, ' + $Uptime.Minutes + ' minutes'
}
Clear-Host
Write-Output ('PowerShell ' + $PSVersionTable.PSVersion.ToString())
Get-Uptime
