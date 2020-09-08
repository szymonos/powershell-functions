<#
.SYNOPSIS
.LINK
https://docs.microsoft.com/en-us/azure/devops/report/extend-analytics/odata-query-guidelines?view=azure-devops
.EXAMPLE
Azure\AdoODataReports.ps1
#>

# functions for Azure storage tables
. '.\.include\func_azcommon.ps1'
. '.\.include\func_azstorage.ps1'

# Retreive Azure DevOps token from Azure Key Vault
Connect-Subscription -Subscription '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3' | Out-Null # ALSO IL DEV
$keyVault = 'also-devops-vault'
$token = (Get-AzKeyVaultSecret -VaultName $keyVault -Name 'AzPSToken').SecretValueText
# Basic authentication string
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($token, $token -join (':'))))

<## WorkItems ##>
# select latest 5 tasks from Scrum Team DevOps area
$uri = 'https://analytics.dev.azure.com/ALSO-ECom/InterLink/_odata/v3.0-preview/WorkItems?$filter=Area/AreaPath eq ''InterLink\Scrum Team DevOps'' and WorkItemType eq ''Task''&$orderby=CreatedDate desc&$top=5'
$uri = 'https://analytics.dev.azure.com/ALSO-ECom/InterLink/_odata/v3.0-preview/WorkItems?$filter=Area/AreaPath eq ''InterLink\Scrum Team DevOps'' and WorkItemType eq ''Task''&$expand=Iteration&$orderby=CreatedDate desc&$top=5'
(Invoke-RestMethod -Uri $uri -Headers @{ Authorization = "Basic $base64AuthInfo" } -Method Get).value

# OData used in PowerQuery
"https://analytics.dev.azure.com/ALSO-ECom/InterLink/_odata/v3.0/WorkItems?$filter=Area/AreaPath eq 'InterLink\Scrum Team DevOps'&$select=WorkItemId,Title,WorkItemType,State,Activity,Priority,CompletedWork,OriginalEstimate,RemainingWork,ParentWorkItemId,StateCategory,StateChangeDate&$expand=Parent($select=Title),Iteration($select=IterationName,StartDate),AssignedTo($select=UserName)"
$uri = 'https://analytics.dev.azure.com/ALSO-ECom/InterLink/_odata/v3.0/WorkItems?$filter=Area/AreaPath eq ''InterLink\Scrum Team DevOps''&$select=WorkItemId,Title,WorkItemType,State,Activity,Priority,CompletedWork,OriginalEstimate,RemainingWork,ParentWorkItemId,StateCategory,StateChangeDate&$expand=Parent($select=Title),Iteration($select=IterationName,StartDate),AssignedTo($select=UserName)'
$workItems = (Invoke-RestMethod -Uri $uri -Headers @{ Authorization = "Basic $base64AuthInfo" } -Method Get).value
$workItems.Count
$workItems | Select-Object * -Last 10
$workItems | Where-Object -Property WorkItemType -eq 'Task' | Select-Object * -Last 10
