## *** Install CHOCOLATEY ***
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# search for package
choco search curl

# Install PowerShell Core and Git
choco install curl -y
choco install terraform -y --version '0.14.11'
choco install openssl -y
choco install sqlserver-odbcdriver -y
choco install vcredist140 -y
choco install nvidia-display-driver -y
# pin application
choco pin
choco pin list
choco pin add -n=terraform
choco pin remove --name terraform
# Update all chocolatey managed apps
choco outdated
cup all -y
cup all -y --whatif

# List local packages
choco list --localonly

# Uninstall package
choco uninstall terraform
# Remove selected package from choco without uninstalling it
choco uninstall terraform -n --skip-autouninstaller

# *CleanUp
choco install choco-cleaner -y
&"$ENV:ChocolateyToolsLocation\BCURRAN3\choco-cleaner.ps1"

# *npm
npm i -g azure-functions-core-tools@3 --unsafe-perm true
[Environment]::SetEnvironmentVariable('FUNCTIONS_CORE_TOOLS_TELEMETRY_OPTOUT',1,'Machine')
npm ls -g
npm update -g

# Update PowerShell 7
<#
https://devblogs.microsoft.com/powershell/announcing-the-powershell-7-0-release-candidate/
#>
Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI"
dotnet tool update --global powershell

# Update PowerShell modules
Update-Module

<#
.SYNOPSIS
Install Microsoft.Data.SqlClient with PowerShell
.LINK
https://gist.github.com/MartinHBA/86c6014175758a07b09fa7bb76ba8e27#microsoftdatasqlclient-with-powershell
#>
# Install .NET CORE 3.0 SDK it must be SDK
choco install dotnetcore-sdk -y
#Check that your PowerShell Core is with NuGet package provider
Get-PackageSource
Get-PackageProvider
Register-PackageSource -Name 'NuGet' -Location 'https://www.nuget.org/api/v2/' -ProviderName 'NuGet'
Install-PackageProvider -Name NuGet -MinimumVersion 3.0.0.1 -Force
Install-Module -Name PowerShellGet -Scope AllUsers -Force -Verbose
Unregister-PackageSource -Name nuget.org

# Install Microsoft.Data.SqlClient required for Azure Active Directory authorization in Azure SQL Databases
# https://devblogs.microsoft.com/azure-sql/microsoft-data-sqlclient-2-0-0-is-now-available/
Find-Package -Name 'Microsoft.Data.SqlClient' -AllVersions -Source 'nuget.org'
Find-Package -Name 'Microsoft.Data.SqlClient.SNI.runtime' -AllVersions -Source 'nuget.org'
Find-Package -Name 'Microsoft.Identity.Client' -AllVersions -Source 'nuget.org'

Install-Package 'Microsoft.Data.SqlClient' -Source 'nuget.org' -SkipDependencies -RequiredVersion '2.0.1'
Install-Package 'Microsoft.Data.SqlClient.SNI.runtime' -Source 'nuget.org' -SkipDependencies -RequiredVersion '2.1.1'
Install-Package 'Microsoft.Identity.Client' -Source 'nuget.org' -SkipDependencies -RequiredVersion '4.35.1'

# Check installed packages
(Get-Package -Name 'Microsoft.Data.SqlClient' -RequiredVersion '2.0.1').Dependencies
(Get-Package -Name 'Microsoft.Identity.Client' -RequiredVersion '4.35.1').Dependencies
Get-Package -Name 'Microsoft.Data.SqlClient' -RequiredVersion '2.0.1' | Select-Object -Property Name, Version, Source, ProviderName -ExpandProperty Dependencies
Get-Package -Name 'Microsoft.Data.SqlClient.SNI.runtime' -AllVersions | Select-Object -Property Name, Version, Source, ProviderName, Dependencies
Get-Package -Name 'Microsoft.Identity.Client' -AllVersions | Select-Object -Property Name, Version, Source, ProviderName, Dependencies
# Remove unwanted package
Get-Package -Name 'Microsoft.Data.SqlClient' -AllVersions
Get-Package -Name 'Microsoft.Data.SqlClient.SNI.runtime' -AllVersions
Get-Package -Name 'Microsoft.Identity.Client' -AllVersions
Get-Package -Name 'Microsoft.Identity.Client' -RequiredVersion '4.21.0' | Uninstall-Package
