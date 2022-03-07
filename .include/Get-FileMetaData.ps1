<#
.SYNOPSIS
Function for parsing WinGet upgrade output
.EXAMPLE
. "$SWD\.include\func_winget.ps1"
Get-WingetResult -u
Invoke-WingetUpgrade -e @('Microsoft.dotnet')
#>

function Get-WingetResult {
    <#
    .SYNOPSIS
    Parse winget upgrade results and return object with list of upgradeable packages.
    #>
    param (
        [Alias('l')]
        [switch]$List,

        [Alias('u')]
        [switch]$Upgrade
    )

    # default to List switch
    if (-not $PSBoundParameters.Count) { $List = $true }

    # get results
    if ($List) {
        [string[]]$result = @(winget list).Where({ $_ -match '^\w' })
    } elseif ($Upgrade) {
        [string[]]$result = @(winget upgrade).Where({ $_ -match '^\w' -and $_ -notmatch '^\d+ +upgrades' })
    }

    # return if winget hasn't returned upgradeable packages
    try {
        if (-not $result[0].StartsWith('Name')) {
            return $result[0]
        }
    } catch {
        return
    }

    # index columns
    $idIndex = $result[0].IndexOf('Id')
    $versionIndex = $result[0].IndexOf('Version')
    $availableIndex = $result[0].IndexOf('Available')
    $sourceIndex = $result[0].IndexOf('Source')
    # Now cycle in real package and split accordingly
    $packages = [Collections.Generic.List[PSObject]]::new()
    for ($i = 1; $i -lt $result.Length; $i++) {
        $package = @{
            Name   = $result[$i].Substring(0, $idIndex).TrimEnd()
            Id     = $result[$i].Substring($idIndex, $versionIndex - $idIndex).TrimEnd()
            Source = $result[$i].Substring($sourceIndex, $result[$i].Length - $sourceIndex)
        }
        if ($List) {
            $package['Version'] = $result[$i].Substring($versionIndex, $sourceIndex - $versionIndex).TrimEnd()
        } elseif ($Upgrade) {
            $package['Version'] = $result[$i].Substring($versionIndex, $availableIndex - $versionIndex).TrimEnd()
            $package['Available'] = $result[$i].Substring($availableIndex, $sourceIndex - $availableIndex).TrimEnd()
        }
        $packages.Add([PSCustomObject]$package)
    }
    if ($List) {
        return $packages | Sort-Object -Property Name | Select-Object Name, Id, Version, Source
    } elseif ($Upgrade) {
        return $packages
    }
}

function Invoke-WingetUpgrade {
    <#
    .SYNOPSIS
    Update all not excluded/unknows packages.
    #>
    [CmdletBinding()]
    param (
        [Alias('e')]
        [Parameter(Mandatory)]
        [string[]]$ExcludedItems
    )
    $packages = Get-WingetResult -Upgrade | Where-Object {
        $_.Id -notin $ExcludedItems -and $_.Version -ne 'Unknown'
    }
    foreach ($item in $packages) {
        [Console]::WriteLine("`e[95m$($item.Name)`e[0m")
        winget.exe upgrade --id $item.Id
    }
    if (-not $packages.Count) {
        Write-Host 'No packages to upgrade.'
    }
}
