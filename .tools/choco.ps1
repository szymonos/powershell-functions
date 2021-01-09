## *** Install CHOCOLATEY ***
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install PowerShell Core and Git
choco install pwsh -y
choco install git -y
choco uninstall openssl -y
choco install azure-cli -y
choco install azure-functions-core-tools-3 --params="'/x64:true'" -y
[Environment]::SetEnvironmentVariable('FUNCTIONS_CORE_TOOLS_TELEMETRY_OPTOUT',1,'Machine')

# Update all chocolatey managed apps
cup all -y

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
Import-Module PSWindowsUpdate
#>
# Get a list of available updates
Get-WindowsUpdate -MicrosoftUpdate -Verbose
# Install everything without prompting
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll
