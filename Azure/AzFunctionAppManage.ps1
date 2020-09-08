<#
.SYNOPSIS
Manage function apps using PowerShell Az module
.DESCRIPTION
Set-AzContext -Subscription 'ALSO IL DEV' | Out-Null
Set-AzContext -Subscription 'ALSO IL QA' | Out-Null
Set-AzContext -Subscription 'ALSO IL PROD' | Out-Null
Set-AzContext -Subscription 'ALSO IS GmbH - Cloud BI (Converted to EA)' | Out-Null
.LINK
https://docs.microsoft.com/en-us/powershell/module/az.functions/?view=azps-4.4.0#functions
.EXAMPLE
Azure\AzFunctionAppManage.ps1
#>

$fAppName = 'also-cdp-dev'
$resGroup = 'CustomerDataPlatformRG'

Get-AzFunctionApp -ResourceGroupName $resGroup -Name $fAppName
Get-AzFunctionApp -ResourceGroupName $resGroup -Name $fAppName | Select-Object *
(Get-AzFunctionApp -ResourceGroupName $resGroup -Name $fAppName).Config.linuxFxVersion
