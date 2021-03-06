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
$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new()

# set variable for Startup Working Directory
$SWD = $PWD.Path

# enable predictive suggestion feature in PSReadLine
try {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
} catch {}

function Prompt {
    $execStatus = $?
    # format execution time of the last command
    $executionTime = if ((Get-History).Count -gt 0) {
        switch ((Get-History)[-1].Duration) {
            { $_.TotalMilliseconds -lt 10 } { '{0:N3} ms' -f $_.TotalMilliseconds }
            { $_.TotalMilliseconds -ge 10 -and $_.TotalMilliseconds -lt 100 } { '{0:N2} ms' -f $_.TotalMilliseconds }
            { $_.TotalMilliseconds -ge 100 -and $_.TotalMilliseconds -lt 1000 } { '{0:N1} ms' -f $_.TotalMilliseconds }
            { $_.TotalSeconds -ge 1 -and $_.TotalSeconds -lt 10 } { '{0:N3} s' -f $_.TotalSeconds }
            { $_.TotalSeconds -ge 10 -and $_.TotalSeconds -lt 100 } { '{0:N2} s' -f $_.TotalSeconds }
            { $_.TotalSeconds -ge 100 -and $_.TotalHours -le 1 } { $_.ToString('mm\:ss\.ff') }
            { $_.TotalHours -ge 1 -and $_.TotalDays -le 1 } { $_.ToString('hh\:mm\:ss') }
            { $_.TotalDays -ge 1 } { "$($_.Days * 24 + $_.Hours):$($_.ToString('mm\:ss'))" }
        }
    } else {
        '0 ms'
    }
    # set prompt path
    $promptPath = $PWD.Path.Replace($HOME, '~').Replace('Microsoft.PowerShell.Core\FileSystem::', '') -replace '\\$', ''
    $split = $promptPath.Split([IO.Path]::DirectorySeparatorChar)
    if ($split.Count -gt 3) {
        $promptPath = [IO.Path]::Join((($split[0] -eq '~') ? '~' : ($IsWindows ? "$($PWD.Drive.Name):" : '')), '...', $split[-2], $split[-1])
    }
    [Console]::Write("[`e[1m`e[38;2;99;143;79m{0}`e[0m]", $executionTime)
    # set arrow color depending on last command execution status
    $execStatus ? [Console]::Write("`e[36m") : [Console]::Write("`e[31m")
    [Console]::Write("`u{279C} `e[1m`e[34m{0}", $promptPath)
    try {
        # show git branch name
        if ($gstatus = @(git status -b --porcelain=v1 2>$null)[0..1]) {
            [Console]::Write(" `e[96m(")
            # parse branch name
            if ($gstatus[0] -match '^## No commits yet') {
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
    <#
    .SYNOPSIS
    Gets the aliases for any cmdlet.#>
    Get-Alias | `
        Where-Object -FilterScript { $_.Definition -match $cmdletname } | `
        Sort-Object -Property Definition, Name | `
        Select-Object -Property Definition, Name
}

function Get-CommandSource ($cmdname) {
    <#
    .SYNOPSIS
    Gets the source directory for command.#>
    (Get-Command $cmdname).Source
}
Set-Alias -Name which -Value Get-CommandSource

function Set-StartupLocation {
    <#
    .SYNOPSIS
    Sets the current working location to the startup working directory.#>
    Set-Location $SWD
}
Set-Alias -Name cds -Value Set-StartupLocation

function Get-DiskUsage {
    [cmdletbinding()]
    param (
        [Alias('p')][Parameter(Position = 0)][string]$Path = '.',
        [Alias('h')][switch]$HumanReadable,
        [Alias('r')][switch]$Recurse,
        [Alias('a')][switch]$All,  # include hidden files and folders
        [Alias('s')][ValidateSet('size', 'count','name')][string]$Sort
    )
    <#
    .SYNOPSIS
    Gets summary size of files inside folders.#>
    # filter for size formatting
    filter formatSize {
        switch ($_) {
            { $_ -ge 1KB -and $_ -lt 1MB } { '{0:0.0}K' -f ($_ / 1KB) }
            { $_ -ge 1MB -and $_ -lt 1GB } { '{0:0.0}M' -f ($_ / 1MB) }
            { $_ -ge 1GB -and $_ -lt 1TB } { '{0:0.0}G' -f ($_ / 1GB) }
            { $_ -ge 1TB } { '{0:0.0}T' -f ($_ / 1TB) }
            Default { "$_.0B" }
        }
    }

    $startPath = Get-Item $Path
    $enumDirs = [IO.EnumerationOptions]::new()
    $enumFiles = [IO.EnumerationOptions]::new()
    $enumDirs.RecurseSubdirectories = $Recurse
    $enumFiles.RecurseSubdirectories = !$Recurse
    $enumDirs.AttributesToSkip = $enumFiles.AttributesToSkip = $All ? 0 : 6

    $dirs = $startPath.GetDirectories('*', $enumDirs)
    if ($Recurse) { $dirs += $startPath }
    if ($Sort) { $result = [Collections.Generic.List[PSObject]]::new() }
    foreach ($dir in $dirs) {
        $items = $dir.GetFiles('*', $enumFiles)
        $size = 0 + ($items | Measure-Object -Property Length -Sum).Sum
        $cnt = ($items | Measure-Object).Count
        $relPath = [IO.Path]::GetRelativePath($startPath.FullName, $dir.FullName)
        if ($Sort) {
            $result.Add([PSCustomObject]@{
                    Size  = $size
                    Count = $cnt
                    Name  = $relPath
                })
        } else {
            if ($HumanReadable) {
                $size = $size | formatSize
                "$(' ' * (7 - $size.Length))$size   $(' ' * (8 - $cnt.ToString().Length))$cnt   $relPath"
            } else {
                "$(' ' * (16 - $size.ToString().Length))$size   $(' ' * (8 - $cnt.ToString().Length))$cnt   $relPath"
            }
        }
    }
    if ($Sort) {
        $result | Sort-Object -Property $Sort | `
            Format-Table -HideTableHeaders @{Name = 'Size'; Expression = { $HumanReadable ? ($_.Size | formatSize) : ($_.Size) }; Align = 'Right' }, Count, Name
    }
}
Set-Alias -Name du -Value Get-DiskUsage

# activate python virtual environment if exists
$init = [IO.Path]::Combine('.vscode', 'init.ps1')
if (Test-Path $init) { & $init }
if ($IsLinux) {
    Set-Alias -Name '.venv/bin/activate' -Value '.venv/bin/Activate.ps1'
}

# PowerShell startup information
Clear-Host
"PowerShell $($PSVersionTable.PSVersion)"
"BootUp: $((Get-Uptime -Since).ToString()) | Uptime: $(Get-Uptime)"
