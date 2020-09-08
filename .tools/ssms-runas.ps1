<#
.SYNOPSIS
Script for automatiion of running SSMS as different user
.DESCRIPTION
Commands required to create encrypted credential in home directory
$user = 'CONTOSO\username'
$pass = ConvertTo-SecureString -String 'p@ssw0rd' -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pass
$cred | Export-CliXml -Path "$($env:USERPROFILE)\cred.xml"
.EXAMPLE
.tools\ssms-runas.ps1           # run as different user
.tools\ssms-runas.ps1 -Elevated # run as different user in administrator mode
#>

param (
    [switch]$Elevated
)

$ssms = Get-ChildItem -Path 'C:\Program Files (x86)' -Filter 'Microsoft SQL Server*' -Directory | `
    Where-Object { $_.Name -ne 'Microsoft SQL Server Compact Edition' } | `
    ForEach-Object { Get-ChildItem -Path $_.FullName -Filter 'ssms.exe' -Recurse -File } | `
    Sort-Object -Property CreationTime | Select-Object -Last 1 -ExpandProperty FullName

$cred = Get-Secret 'secret'

if ($Elevated) {
    Start-Process powershell -Credential $cred -ArgumentList "-noprofile -command &{Start-Process '$ssms' -verb runas}"
} else {
    Start-Process -FilePath $ssms -Credential $cred
}
