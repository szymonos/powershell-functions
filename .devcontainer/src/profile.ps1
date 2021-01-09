<#
.SYNOPSIS
My PowerShell 7 profile. It uses updated PSReadLine module and git.
.LINK
https://github.com/PowerShell/PSReadLine
.EXAMPLE
Install-Module PSReadLine -AllowPrerelease -Force
code $Profile.CurrentUserAllHosts
#>
$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
# enable predictive suggestion feature in PSReadLine
Set-PSReadLineOption -PredictionSource History -ErrorAction 'SilentlyContinue'
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
    # show only current folder or ~ in home directory as prompt path
    $promptPath = if ($PWD.ToString() -eq $env:USERPROFILE) { '~' } else { Split-Path $PWD -Leaf }
    [Console]::Write("[`e[1m`e[38;2;99;143;79m{0}`e[0m]", $executionTime)
    # set arrow color depending on last command execution status
    if($execStatus) {
        [Console]::Write("`e[36m`u{279C}`e[0m ")
    } else {
        [Console]::Write("`e[31m`u{279C}`e[0m ")
    }
    [Console]::Write("`e[1m`e[34m{0} ", $promptPath)
    try {
        # show git branch name
        if ($gstatus = git status -b --porcelain=v1 2>$null) {
            [Console]::Write("`e[96m(")
            # format branch name color depending on git diff status
            if($gstatus.Count -gt 1) {
                [Console]::Write("`e[91m")  # red
            } else {
                [Console]::Write("`e[92m")  # green
            }
            $branch = $gstatus[0].Split(' ')[1].Split('.')[0]
            [Console]::Write("{0}`e[96m)", $branch)
        }
    } catch { }
    return "`e[0m$ "
}
