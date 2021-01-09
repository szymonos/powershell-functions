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

# Get module path
(Get-Module oh-my-posh).ModuleBase

# Check powershell version
$PSVersionTable

## Edit PowerShell global profile
code $Profile.CurrentUserCurrentHost
code $Profile.CurrentUserAllHosts
code $Profile.AllUsersCurrentHost
code $Profile.AllUsersAllHosts
code $profile  # in Linux

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
$modulePath = $userModulePath, ([Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')) -join (';')
[Environment]::SetEnvironmentVariable('PSModulePath', $modulePath, 'Machine')

# Remove path from env
$remPath = 'C:\Python38\Scripts\'
$p = [Environment]::GetEnvironmentVariable('Path', 'Machine') -split(';') | Where-Object {$_ -notlike $remPath}
# $p = [Environment]::GetEnvironmentVariable('Path', 'Machine') -split(';') | Select-Object -Unique
[Environment]::SetEnvironmentVariable('Path', ($p -join(';')), 'Machine')

RefreshEnv.cmd
