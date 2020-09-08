## *** Install CHOCOLATEY ***
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install PowerShell Core and Git
choco install pwsh -y
choco install git -y
choco install azure-cli -y
choco install dotnetfx -y
choco install dotnetcore-runtime -y
choco install dotnetcore-sdk -y
choco install firacode-ttf -y
choco install cascadiacode -y
choco install azure-functions-core-tools-3 --params "'/x64'" -y
choco install notepadplusplus -y
choco install openssl -y
choco install sqlserver-odbcdriver -y
choco install python3 -y

# Update all chocolatey managed apps
cup all -y
cup all -y --whatif

# List local packages
choco list --localonly

# Uninstall package
choco uninstall python3

# Removoe selected package from choco without uninstalling it
choco uninstall python3 -n --skip-autouninstaller

# Update PowerShell 7
<#
https://devblogs.microsoft.com/powershell/announcing-the-powershell-7-0-release-candidate/
#>
Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI"
dotnet tool update --global powershell

# Update PowerShell modules
Update-Module

<# Windows Update
Install-Module -Name PSWindowsUpdate
Get-Content Function:\Start-WUScan
#>
# Get a list of available updates
Get-WindowsUpdate -MicrosoftUpdate -Verbose
# Install everything without prompting
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll

# Install Microsoft.Data.SqlClient with PowerShell
<#
https://gist.github.com/MartinHBA/86c6014175758a07b09fa7bb76ba8e27#microsoftdatasqlclient-with-powershell
#>
# Install .NET CORE 3.0 SDK it must be SDK
choco install dotnetcore-sdk -y
#Check that your PowerShell Core is with NuGet package provider
Get-PackageProvider
Register-PackageSource -Name 'NuGet' -Location 'https://www.nuget.org/api/v2' -ProviderName 'NuGet'

# Install Microsoft.Data.SqlClient required for Azure Active Directory authorization in Azure SQL Databases
# https://devblogs.microsoft.com/azure-sql/microsoft-data-sqlclient-2-0-0-is-now-available/
Find-Package -Name 'Microsoft.Data.SqlClient' -AllVersions -ProviderName 'NuGet'
Find-Package -Name 'Microsoft.Data.SqlClient.SNI.runtime' -AllVersions -ProviderName 'NuGet'
Find-Package -Name 'Microsoft.Identity.Client' -AllVersions -ProviderName 'NuGet'

Install-Package 'Microsoft.Data.SqlClient' -RequiredVersion 1.1.3 -ProviderName 'NuGet' -SkipDependencies
Install-Package 'Microsoft.Data.SqlClient.SNI.runtime' -ProviderName 'NuGet' -SkipDependencies
Install-Package 'Microsoft.Identity.Client' -RequiredVersion 3.0.9 -ProviderName 'NuGet' -SkipDependencies
# Copy dependent DLL (Microsoft.Data.SqlClient.SNI.dll - correct runtime, in my case x64) to folder with your main DLL
$sniRuntime = Get-ChildItem -Path 'C:\Program Files\PackageManagement\NuGet\Packages' -Filter 'Microsoft.Data.SqlClient.SNI.runtime.*' -Directory | `
    Sort-Object -Property Name | Select-Object -Last 1 | `
    Get-ChildItem -Filter 'runtimes\win-x64\native\Microsoft.Data.SqlClient.SNI.dll' -File
$destDir = Get-ChildItem -Path 'C:\Program Files\PackageManagement\NuGet\Packages' -Filter 'Microsoft.Data.SqlClient.??.??.??' -Directory | `
    Sort-Object -Property Name | Select-Object -Last 1 | `
    Get-ChildItem -Filter 'lib\netcoreapp2.1' -Directory
Copy-Item $sniRuntime -Destination $destDir

# Remove unwanted package
Get-Package -Name 'Microsoft.Identity.Client' -AllVersions
Get-Package -Name 'Microsoft.Data.SqlClient' -RequiredVersion 1.1.1 | Uninstall-Package
