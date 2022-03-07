#Requires -Version 7.0
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Script for updating PowerShell modules and cleaning-up old versions.
.EXAMPLE
.tools\PSModulesManage.ps1      # *update and clean up modules
.tools\PSModulesManage.ps1 -u   # *update modules only
.tools\PSModulesManage.ps1 -c   # *clean up modules only
#>

param (
    [Alias('u')][switch]$Update,
    [Alias('c')][switch]$CleanUp
)

Clear-Host
if (-not $CleanUp) {
    "$($PSStyle.Foreground.Yellow)Update all modules.$($PSStyle.Reset)"
    Update-Module -AcceptLicense
    "$($PSStyle.Foreground.Yellow)Check prerelease versions.$($PSStyle.Reset)"
    $prerelease = (Get-InstalledModule).Where({ $_.Version -match '-' })
    foreach ($mod in $prerelease) {
        "- $($mod.Name)"
        (Find-Module -Name $mod.Name -AllowPrerelease).ForEach({
                if ($_.Version -ne $mod.Version) {
                    "$($PSStyle.Foreground.Green)Found newer version: $($PSStyle.Bold)$($_.Version)$($PSStyle.Reset)"
                    Install-Module -Name $mod.Name -AllowPrerelease -AllowClobber -Force -AcceptLicense
                }
            })
    }
}

if (-not $Update) {
    "$($PSStyle.Foreground.Yellow)Get installed modules.$($PSStyle.Reset)"
    $installedModules = Get-InstalledModule | Sort-Object -Property Name

    foreach ($mod in $installedModules) {
        "`n$($PSStyle.Underline)Check $($mod.Name)$($PSStyle.Reset)"
        $allVersions = @(Get-InstalledModule $mod.Name -AllVersions)
        $latestVersion = ($allVersions | Sort-Object PublishedDate)[-1].Version
        if ($allVersions.Count -eq 1) {
            "$($PSStyle.Foreground.Green)latest version $($PSStyle.Bold)v$latestVersion$($PSStyle.BoldOff) installed$($PSStyle.Reset)"
        } else {
            "$($PSStyle.Foreground.Cyan)$($allVersions.Count) versions of the module found, latest: $($PSStyle.Bold)v$latestVersion$($PSStyle.Reset)"
            'uninstall'
            foreach ($v in $allVersions.Where({ $_.Version -ne $latestVersion })) {
                "- $($PSStyle.Foreground.BrightMagenta)v$($v.Version)$($PSStyle.Reset)"
                $v | Uninstall-Module -Force
            }
        }
    }
}
"`nDone!"
