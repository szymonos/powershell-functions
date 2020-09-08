<#
.Description
https://docs.microsoft.com/en-us/powershell/module/az.resources/set-azresourcelock?view=azps-2.8.0#parameters
https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.commands.resourcemanager.cmdlets.entities.locks.locklevel?view=azurerm-ps
https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azresourcelock?view=azps-2.8.0#examples
Set-AzContext -Subscription 'ALSO IL DEV' | Out-Null
Set-AzContext -Subscription 'ALSO IL QA' | Out-Null
Set-AzContext -Subscription 'ALSO IL PROD' | Out-Null

LockLevel:
0 CanNotDelete
1 ReadOnly
.Example
Set-AzResourceLock -LockLevel CanNotDelete -LockNotes "Updated note" -LockName "ContosoSiteLock" -ResourceName "ContosoSite" -ResourceType "microsoft.web/sites" -ResourceGroupName "ResourceGroup11"
DevOps\ResourceGroupLock.ps1 -CreateLock 1
DevOps\ResourceGroupLock.ps1 -CreateLock 0
#>
param (
    [bool]$CreateLock = $true
)

$resourceGroupName = 'Also-IL-DEV'
$lockName = 'NoDelete'

if ($CreateLock) {
    New-AzResourceLock -LockName $lockName -LockLevel CanNotDelete -ResourceGroupName $resourceGroupName -Force
}
else {
    Remove-AzResourceLock -LockName $lockName -ResourceGroupName $resourceGroupName -Force
}
