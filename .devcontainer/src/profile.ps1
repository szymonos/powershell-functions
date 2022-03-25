#Requires -Version 7.2
#Requires -Modules PSReadLine, posh-git

#region startup settings
# Import posh-git module for git autocompletion
Import-Module posh-git; $GitPromptSettings.EnablePromptStatus = $false
# make PowerShell console Unicode (UTF-8) aware
$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new()
# set culture to English Sweden for ISO-8601 datetime settings
[Threading.Thread]::CurrentThread.CurrentCulture = 'en-SE'
# change PSStyle for directory coloring
$PSStyle.FileInfo.Directory = "$($PSStyle.Bold)$($PSStyle.Foreground.Blue)"
# configure PSReadLine setting
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Chord Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord F2 -Function SwitchPredictionView
Set-PSReadLineKeyHandler -Chord Shift+Tab -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord Alt+j -Function NextHistory
Set-PSReadLineKeyHandler -Chord Alt+k -Function PreviousHistory
# set Startup Working Directory variable
$SWD = $PWD.Path
#endregion

#region functions
# navigation functions
function cds { Set-Location $SWD }
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function ..... { Set-Location ../../../.. }

function ll {
    $arguments = $args.ForEach({ $_ -match ' ' ? "'$_'" : $_ })
    Invoke-Expression "Get-ChildItem $arguments -Force"
}

function src { . $PROFILE.CurrentUserAllHosts }

function Format-Duration ([timespan]$TimeSpan) {
    <#
    .SYNOPSIS
    Print timespan in human readable format.#>
    switch ($TimeSpan) {
        { $_.TotalMilliseconds -gt 0 -and $_.TotalMilliseconds -lt 10 } { '{0:N2}ms' -f $_.TotalMilliseconds }
        { $_.TotalMilliseconds -ge 10 -and $_.TotalMilliseconds -lt 100 } { '{0:N1}ms' -f $_.TotalMilliseconds }
        { $_.TotalMilliseconds -ge 100 -and $_.TotalMilliseconds -lt 1000 } { '{0:N0}ms' -f $_.TotalMilliseconds }
        { $_.TotalSeconds -ge 1 -and $_.TotalSeconds -lt 10 } { '{0:N3}s' -f $_.TotalSeconds }
        { $_.TotalSeconds -ge 10 -and $_.TotalSeconds -lt 100 } { '{0:N2}s' -f $_.TotalSeconds }
        { $_.TotalSeconds -ge 100 -and $_.TotalHours -le 1 } { $_.ToString('mm\:ss\.ff') }
        { $_.TotalHours -ge 1 -and $_.TotalDays -le 1 } { $_.ToString('hh\:mm\:ss') }
        { $_.TotalDays -ge 1 } { "$($_.Days * 24 + $_.Hours):$($_.ToString('mm\:ss'))" }
        Default { '0ms' }
    }
}

function Get-CmdletAlias ([string]$cmdletname) {
    <#
    .SYNOPSIS
    Get the aliases for any cmdlet.#>
    Get-Alias | `
        Where-Object -FilterScript { $_.Definition -match $cmdletname } | `
        Sort-Object -Property Definition, Name | `
        Select-Object -Property Definition, Name
}

# functions
function Invoke-Sudo { & /usr/bin/env sudo pwsh -NoProfile -Command "& $args" }
function grep { $input | & /usr/bin/env grep --color=auto $args }
function ls { & /usr/bin/env ls --color=auto --time-style=long-iso --group-directories-first $args }
function l { ls -1 }
function la { ls -lAh }
function lsa { ls -lah }
#endregion

#region aliases
Set-Alias -Name ga -Value Get-Alias
Set-Alias -Name gca -Value Get-CmdletAlias
Set-Alias -Name _ -Value Invoke-Sudo
#endregion

#region prompt
function Prompt {
    $execStatus = $?
    # get execution time of the last command
    $executionTime = (Get-History).Count -gt 0 ? (Format-Duration(Get-History)[-1].Duration) : $null
    # get prompt path
    $promptPath = $PWD.Path.Replace($HOME, '~').Replace('Microsoft.PowerShell.Core\FileSystem::', '') -replace '\\$'
    $split = $promptPath.Split([IO.Path]::DirectorySeparatorChar)
    if ($split.Count -gt 3) {
        $promptPath = [IO.Path]::Join((($split[0] -eq '~') ? '~' : ($IsWindows ? "$($PWD.Drive.Name):" : $split[1])), '..', $split[-1])
    }
    # write last execution time
    if ($executionTime) {
        [Console]::Write("[$($PSStyle.Foreground.BrightYellow)$executionTime$($PSStyle.Reset)] ")
    }
    # write last execution status
    [Console]::Write("$($PSStyle.Bold){0}`u{2192} ", $execStatus ? $PSStyle.Foreground.BrightGreen : $PSStyle.Foreground.BrightRed)
    # write prompt path
    [Console]::Write("$($PSStyle.Foreground.Blue)$promptPath$($PSStyle.Reset) ")
    # write git branch/status
    try {
        # get git status
        $gstatus = @(git status -b --porcelain=v2 2>$null)[1..4]
        if ($gstatus) {
            # get branch name and upstream status
            $branch = $gstatus[0].Split(' ')[2] + ($gstatus[1] -match 'branch.upstream' ? $null : " `u{21E1}")
            # format branch name color depending on working tree status
            [Console]::Write("{0}`u{E0A0}$branch ", ($gstatus | Select-String -Pattern '^(?!#)' -Quiet) ? "`e[38;2;255;146;72m" : "`e[38;2;212;170;252m")
        }
    } catch {}
    return '{0}{1} ' -f ($PSStyle.Reset, '>' * ($nestedPromptLevel + 1))
}
#endregion

#region startup information
"$($PSStyle.Foreground.BrightWhite){0} | PowerShell $($PSVersionTable.PSVersion)$($PSStyle.Reset)" `
    -f (Select-String -Pattern '^PRETTY_NAME=(.*)' -Path /etc/os-release).Matches.Groups[1].Value.Trim("`"|'")
#endregion
