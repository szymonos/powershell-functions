<#
.SYNOPSIS
Remove merged branches from local git repo
.EXAMPLE
.tools\.submodules\GitRemoveBranches.ps1
.tools\.submodules\GitRemoveBranches.ps1 -Branch 'dev'
.tools\.submodules\GitRemoveBranches.ps1 -RepoFolder 'C:\Source\Repos\BiznesLink' -IncludeRemote
.tools\.submodules\GitRemoveBranches.ps1 -DelBranches
.tools\.submodules\GitRemoveBranches.ps1 -DelBranches -Branch 'dev'
.tools\.submodules\GitRemoveBranches.ps1 -IncludeRemote
.tools\.submodules\GitRemoveBranches.ps1 -IncludeRemote -Branch 'dev'
.tools\.submodules\GitRemoveBranches.ps1 -IncludeRemote -DelBranches
.tools\.submodules\GitRemoveBranches.ps1 -IncludeRemote -DelBranches -Branch 'dev'
git help git
#>
param (
    [switch]$DelBranches,
    [switch]$IncludeRemote,
    [ValidateScript( { Test-Path $_ -PathType 'Container' } )]$RepoFolder,
    [string]$Branch = 'master'
)

# Include functions
. '.include\func_forms.ps1'

$RepoFolder ??= Get-Folder -InitialDirectory 'C:\Source\Repos'
if ($RepoFolder -eq 'C:\Source\Repos\') { break }

$currentLocation = Get-Location
Set-Location $RepoFolder

#enumerate commits to push/pull
git checkout $Branch --quiet
$behind = git rev-list 'HEAD..@{u}' --count
$ahead = git rev-list '@{u}..HEAD' --count
# pull commits if current brach is behind 'origin/master'
if ($behind -gt 0 -and $ahead -eq 0) {
    git pull --quiet
}

if ($DelBranches) {
    git remote update origin --prune
}

if ($IncludeRemote) {
    $merged = git branch -a --merged | ForEach-Object { ($_ -replace ('remotes/origin/', '') -replace ('\*', '')).trim() } | Where-Object { $_ -notin ('dev', 'qa', 'master') -and $_ -notlike 'HEAD*' }
    $unmerged = git branch -a --no-merged | ForEach-Object { ($_ -replace ('remotes/origin/', '') -replace ('\*', '')).trim() } | Where-Object { $_ -notin 'dev', 'qa', 'master' }
} else {
    $merged = git branch --merged | ForEach-Object { ($_ -replace ('\*', '')).trim() } | Where-Object { $_ -notin 'dev', 'qa', 'master' }
    $unmerged = git branch --no-merged | ForEach-Object { ($_ -replace ('\*', '')).trim() } | Where-Object { $_ -notin 'dev', 'qa', 'master' }
}

$branches = @()
if (($merged | Measure-Object).Count -eq 0) {
    Write-Output "`e[92mThere are no merged branches!`e[0m"
} else {
    #Write-Output "`e[96mMerged branches"
    foreach ($br in $merged) {
        #$br = $merged[0]
        if ($DelBranches) {
            if ($IncludeRemote) {
                git push origin --delete $br
            } else {
                git branch --delete $br
            }
        } else {
            $branches += [PSCustomObject]@{
                Status = 'Merged'
                Branch = $br
                Behind = git rev-list "origin/$br..HEAD" --count
                Ahead  = 0
            }
        }
    }
}

if (($unmerged | Measure-Object).Count -eq 0) {
    Write-Output "`e[92mThere are no unmerged branches!`e[0m"
} else {
    if ($DelBranches) {
        git branch -a --no-merged | `
            ForEach-Object { ($_).trim() } | `
            Where-Object { $_ -notin ('dev', 'qa', 'master') -and $_ -notlike 'remotes*' } | `
            ForEach-Object { git branch -D $_ }
    } else {
        foreach ($br in $unmerged) {
            $branches += [PSCustomObject]@{
                Status = 'Unmerged'
                Branch = $br
                Behind = git rev-list "origin/$br..HEAD" --count
                Ahead  = git rev-list "HEAD..origin/$br" --count
            }
        }
    }
}
if ($branches) {
    $branches
}

[System.Console]::WriteLine()
Set-Location $currentLocation
