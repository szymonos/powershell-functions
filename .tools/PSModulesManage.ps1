<#
.Description
Remove old versions of Powershell modules
.Example
.tools\PSModulesManage.ps1
.tools\PSModulesManage.ps1 2 --to remove old versions
.tools\PSModulesManage.ps1 3 --to update modules and remove old versions
#>

param (
    [int]$mode = 0
)

Clear-Host
$mods = Get-InstalledModule

switch ($mode) {
    { $_ -eq 3 } {
        Write-Host 'Updating all modules' -ForegroundColor Green
        Update-Module -AcceptLicense
    }
    { $_ -in (2, 3) } {
        Write-Output 'This will remove all old versions of installed modules.'
        Write-Host "Be sure to run this as an admin!`n" -ForegroundColor Yellow

        foreach ($mod in $mods) {
            Write-Output "Checking $($mod.name)"
            $latest = Get-InstalledModule $mod.name
            $specificmods = Get-InstalledModule $mod.name -AllVersions
            Write-Host "$(($specificmods | Measure-Object).count) version(s) of this module found [$($mod.name)]" -ForegroundColor Cyan

            foreach ($sm in $specificmods) {
                if ($sm.version -ne $latest.version) {
                    Write-Host "uninstalling $($sm.name) - $($sm.version) [latest is $($latest.version)]" -ForegroundColor Magenta
                    $sm | Uninstall-Module -Force
                    Write-Host "done uninstalling $($sm.name) - $($sm.version)" -ForegroundColor Green
                    Write-Output '    --------'
                }
            }
            Write-Output '------------------------'
        }
        Write-Output 'Done'
    }
    { $_ -ne 2 } {
        Write-Output "This will report all modules with duplicate (older and newer) versions installed.`n"

        foreach ($mod in $mods) {
            Write-Output "Checking $($mod.name)"
            $specificmods = Get-InstalledModule $mod.name -AllVersions
            Write-Host "$(($specificmods | Measure-Object).count) version(s) of this module found" -ForegroundColor Cyan

            foreach ($sm in $specificmods) {
                if ($sm.version -eq $mod.version) { $color = 'Green' }
                else { $color = 'Magenta' }
                Write-Host "$($sm.name) v$($sm.version) [latest is $($mod.version)]" -ForegroundColor $color
            }
            Write-Output '------------------------'
        }
    }
}
