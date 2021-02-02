<#
.SYNOPSIS
My PowerShell 7 profile. It uses updated PSReadLine module and git.
.LINK
https://github.com/PowerShell/PSReadLine
.EXAMPLE
Install-Module PSReadLine -AllowPrerelease -Force
code $Profile.CurrentUserAllHosts
#>
# make PowerShell console Unicode (UTF-8) aware
$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
# set variable for Startup Working Directory
$SWD = $PWD.Path
# enable predictive suggestion feature in PSReadLine
try { Set-PSReadLineOption -PredictionSource History } catch {}
function Prompt {
    $execStatus = $?
    # format execution time of the last command
    $executionTime = if ((Get-History).Count -gt 0) {
        switch ((Get-History)[-1].Duration) {
            { $_.TotalMilliseconds -lt 10 } { "{0:N3} ms" -f $_.TotalMilliseconds }
            { $_.TotalMilliseconds -ge 10 -and $_.TotalMilliseconds -lt 100 } { "{0:N2} ms" -f $_.TotalMilliseconds }
            { $_.TotalMilliseconds -ge 100 -and $_.TotalMilliseconds -lt 1000 } { "{0:N1} ms" -f $_.TotalMilliseconds }
            { $_.TotalSeconds -ge 1 -and $_.TotalSeconds -lt 10 } { "{0:N3} s" -f $_.TotalSeconds }
            { $_.TotalSeconds -ge 10 -and $_.TotalSeconds -lt 100 } { "{0:N2} s" -f $_.TotalSeconds }
            { $_.TotalSeconds -ge 100 -and $_.TotalHours -le 1 } { $_.ToString('mm\:ss\.ff') }
            { $_.TotalHours -ge 1 -and $_.TotalDays -le 1 } { $_.ToString('hh\:mm\:ss') }
            { $_.TotalDays -ge 1 } { "$($_.Days * 24 + $_.Hours):$($_.ToString('mm\:ss'))" }
        }
    } else {
        "0 ms"
    }
    # set prompt path
    $promptPath = $PWD.Path.Replace($HOME, '~').Replace('Microsoft.PowerShell.Core\FileSystem::', '') -replace '\\$', ''
    $split = $promptPath.Split([System.IO.Path]::DirectorySeparatorChar)
    if ($split.Count -gt 3) {
        $promptPath = [System.IO.Path]::Join((($split[0] -eq '~') ? '~' : $null), '...', $split[-2], $split[-1])
    }
    [Console]::Write("[`e[1m`e[38;2;99;143;79m{0}`e[0m]", $executionTime)
    # set arrow color depending on last command execution status
    $execStatus ? [Console]::Write("`e[36m") : [Console]::Write("`e[31m")
    [Console]::Write("`u{279C} `e[1m`e[34m{0}", $promptPath)
    try {
        # show git branch name
        if ($gstatus = [string[]]@(git status -b --porcelain=v1 2>$null)) {
            [Console]::Write(" `e[96m(")
            # parse branch name
            if ($gstatus[0] -like '## No commits yet*') {
                $branch = $gstatus[0].Split(' ')[5]
            } else {
                $branch = $gstatus[0].Split(' ')[1].Split('.')[0]
            }
            # format branch name color depending on working tree status
            ($gstatus.Count -eq 1) ? [Console]::Write("`e[92m") : [Console]::Write("`e[91m")
            [Console]::Write("{0}`e[96m)", $branch)
        }
    } catch {}
    return "`e[0m{0} " -f ('>' * ($nestedPromptLevel + 1))
}
function Get-CmdletAlias ($cmdletname) {
    <#.SYNOPSIS
    Gets the aliases for any cmdlet.#>
    Get-Alias |
    Where-Object -FilterScript { $_.Definition -like "*$cmdletname*" } |
    Sort-Object -Property Definition, Name |
    Select-Object -Property Definition, Name
}
function Set-StartupLocation {
    <#.SYNOPSIS
    Sets the current working location to the startup working directory.#>
    Set-Location $SWD
}
Set-Alias -Name cds -Value Set-StartupLocation
Set-Alias -Name which -Value Get-Command

# PowerShell startup information
Clear-Host
"PowerShell $($PSVersionTable.PSVersion)"
"BootUp: $((Get-Uptime -Since).ToString()) | Uptime: $(Get-Uptime)"
