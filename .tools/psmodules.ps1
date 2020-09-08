# Install module Az to manage Azure
Install-Module Az -AllowClobber
Install-Module SqlServer
Install-Module CosmosDB

# Check installed modules
Get-InstalledModule
Get-InstalledModule | Select-Object -Property Version, Name, Repository, InstalledLocation
Get-InstalledModule -Name Az.Resources -AllVersions

# Uninstall specific version of module
$module = Get-InstalledModule -Name Az.Resources -AllowPrerelease -RequiredVersion '4.0.2-preview'
Uninstall-Module -Name $module.Name -AllowPrerelease -RequiredVersion $module.Version -Force:$true -ErrorAction Stop

# Get commands in module
Get-Command -Module Az.Resources

# Check powershell version
$PSVersionTable

## Edit PowerShell global profile
code $Profile.CurrentUserCurrentHost
code $Profile.CurrentUserAllHosts
code $Profile.AllUsersCurrentHost
code $Profile.AllUsersAllHosts

# List all environment variables
Get-ChildItem Env:
[Environment]::GetEnvironmentVariables()
[Environment]::GetEnvironmentVariables("Process")
[Environment]::GetEnvironmentVariables("Machine")
[Environment]::GetEnvironmentVariables("User")

# Remove variable
Remove-Item Env:\MyTestVariable
[Environment]::SetEnvironmentVariable('MyTestVariable',$null,'User')

## Get PSModulePath environment variable
[Environment]::GetEnvironmentVariable('PSModulePath', 'Process')
[Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
[Environment]::GetEnvironmentVariable('PSModulePath', 'User')

# Set PSModulePath environment variable
$userModulePath = "$($env:APPDATA)\PowerShell\Modules"
if (!(Test-Path $userModulePath)) { New-Item $userModulePath -ItemType Directory -Force }
$modulePath = $userModulePath, ([Environment]::GetEnvironmentVariable('PSModulePath', 'Process')) -join (';')
[Environment]::SetEnvironmentVariable('PSModulePath', $modulePath, 'Process')

# Remove path from env
$remPath = 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\'
$p = [Environment]::GetEnvironmentVariable('Path', 'Process') -split(';') | Where-Object {$_ -ne $remPath}
[Environment]::SetEnvironmentVariable('Path', ($p -join(';')), 'Process')

## Install module for all users in "$env:ProgramFiles\PowerShell\Modules" location
<# https://docs.microsoft.com/en-us/powershell/module/powershellget/install-module?view=powershell-7#parameters #>
Install-Module Az -Scope AllUsers -AllowClobber
