<#
.DESCRIPTION
Remove merged branches from local git repo
.EXAMPLE
.tools\.submodules\GitCleanBranches.ps1
.tools\.submodules\GitCleanBranches.ps1 -DelBranches
git help git
#>
param (
    [switch]$DelBranches,
    [ValidateScript( { Test-Path $_ -PathType 'Container' } )]$RepoFolder
)

# Include functions
. '.include\func_forms.ps1'

$RepoFolder ??= Get-Folder

$currentLocation = Get-Location
Set-Location $RepoFolder

#enumerate commits to push/pull
git checkout 'master' --quiet
$behind = git rev-list 'HEAD..@{u}' --count
$ahead = git rev-list '@{u}..HEAD' --count
# pull commits if current brach is behind 'origin/master'
if ($behind -gt 0 -and $ahead -eq 0) {
    git pull --quiet
}

if ($DelBranches) {
    git remote update origin --prune
}

$merged = git branch --merged | ForEach-Object { ($_ -replace ('\*', '')).trim() } | Where-Object { $_ -notin 'dev', 'qa', 'master' }
$unmerged = git branch --no-merged | ForEach-Object { ($_ -replace ('\*', '')).trim() } | Where-Object { $_ -notin 'dev', 'qa', 'master' }

if (($merged | Measure-Object).Count -eq 0) {
    Write-Output "`e[32mThere are no merged branches!`e[0m"
}
else {
    Write-Output 'Merged branches:'
    foreach ($br in $merged) {
        Write-Output (' - ' + $br)
        if ($DelBranches) {
            git branch --delete $br
        }
    }
}

if (($unmerged | Measure-Object).Count -eq 0) {
    Write-Output "`e[32mThere are no unmerged branches!`e[0m"
}
else {
    Write-Output "`nUnmerged branches:"
    foreach ($um in $unmerged) {
        Write-Output (' - ' + $um)
    }
    if ($DelBranches) {
        git branch -a --no-merged | `
            ForEach-Object { ($_).trim() } | `
            Where-Object { $_ -notin ('dev', 'qa', 'master') -and $_ -notlike 'remotes*' } | `
            ForEach-Object { git branch -D $_ }
    }
}
Write-Output ''
git status --porcelain --branch
Set-Location $currentLocation
