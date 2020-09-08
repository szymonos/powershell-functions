<#
.SYNOPSIS
Run automation runbooks
.LINK
https://docs.microsoft.com/en-us/powershell/module/az.automation/Start-AzAutomationRunbook?view=azps-4.3.0
.EXAMPLE
Azure\runbooks\RunbookStart.ps1
#>

## DEV
'.include\func_azcommon.ps1'; Connect-Subscription -Subscription '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3'

$account = 'autoacc-devops-dev'
$resourceGroup = 'DevOps-RG-DEV'

# Update-AutomationAzureModulesForAccount
$runbookName = 'Update-AutomationAzureModulesForAccount'
$parameters = @{'RESOURCEGROUPNAME'=$resourceGroup;'AUTOMATIONACCOUNTNAME'=$account;'AZUREMODULECLASS'='Az'}
Start-AzAutomationRunbook -AutomationAccountName $account -Name $runbookName -ResourceGroupName $resourceGroup -Parameters $parameters

# Update-AutomationAzureModulesForAccount
$runbookName = 'AzCostBillingsUpdate'
Start-AzAutomationRunbook -AutomationAccountName $account -Name $runbookName -ResourceGroupName $resourceGroup

## PROD
'.include\func_azcommon.ps1'; Connect-Subscription -Subscription '4933eec9-928e-4cca-8ce3-8f0ea0928d36'

$account = 'autoacc-devops-prod'
$resourceGroup = 'DevOps-RG-PROD'

# Update-AutomationAzureModulesForAccount
$runbookName = 'Update-AutomationAzureModulesForAccount'
$parameters = @{'RESOURCEGROUPNAME'=$resourceGroup;'AUTOMATIONACCOUNTNAME'=$account;'AZUREMODULECLASS'='Az'}
Start-AzAutomationRunbook -AutomationAccountName $account -Name $runbookName -ResourceGroupName $resourceGroup -Parameters $parameters


## QA
'.include\func_azcommon.ps1'; Connect-Subscription -Subscription 'f37a52e7-fafe-401f-b7dd-fc50ea03fcfa'

$account = 'autoacc-devops-qa'
$resourceGroup = 'DevOps-RG-QA'

# Update-AutomationAzureModulesForAccount
$runbookName = 'Update-AutomationAzureModulesForAccount'
$parameters = @{'RESOURCEGROUPNAME'=$resourceGroup;'AUTOMATIONACCOUNTNAME'=$account;'AZUREMODULECLASS'='Az'}
Start-AzAutomationRunbook -AutomationAccountName $account -Name $runbookName -ResourceGroupName $resourceGroup -Parameters $parameters
