<#
.Description
https://docs.microsoft.com/en-us/powershell/module/az.Resources/Get-azRoleAssignment
Set-AzContext -Subscription 'ALSO IL DEV' | Out-Null
Set-AzContext -Subscription 'ALSO IL QA' | Out-Null
Set-AzContext -Subscription 'ALSO IL PROD' | Out-Null
.Example
C:\Source\Git\DevOps\Azure\RoleAssignments.ps1
#>
$roleAssignmentsAll = Get-AzRoleAssignment | Select-Object -Property DisplayName, SignInName, ObjectType, RoleDefinitionName, Scope
$roleAssignmentsAll | Where-Object -Property ObjectType -eq 'User' | Sort-Object -Property DisplayName | Select-Object -Property SignInName, RoleDefinitionName, Scope
Get-AzRoleAssignment | Where-Object -Property ObjectType -eq 'User' | Sort-Object -Property DisplayName | Select-Object -Property DisplayName, RoleDefinitionName, Scope

$resourceGroup = 'Also-Ecom-PROD'
$resourceGroup = 'DevOps-RG-PROD'
$resourceGroup = 'Also-IL-PROD'
Get-AzRoleAssignment -ResourceGroupName $resourceGroup | Where-Object -Property ObjectType -eq 'User' | Select-Object -Property SignInName, RoleDefinitionName, Scope

$signName = 'robert.kucinski@also.com'
Get-AzRoleAssignment -SignInName $signName | Select-Object -Property RoleDefinitionName, Scope

# Get all RBAC role definitions
Get-AzRoleDefinition | Select-Object -Property Id, Name, Description | Sort-Object -Property Name

## Copy assignments from one user to other
$signName = 'robert.kucinski@also.com'
$i = 0; $roleAssignments = Get-AzRoleAssignment -SignInName $signName | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name 'Id' -Value $i -PassThru; $i++ } | Select-Object Id, SignInName, RoleDefinitionName, Scope
$roleAssignments
$signName = 'Krzysztof.Anusiewicz@also.com'
foreach ($role in $roleAssignments) {
    #$role = $roleAssignments[1]
    New-AzRoleAssignment -Scope $role.Scope -SignInName $signName -RoleDefinitionName $role.RoleDefinitionName | `
        Select-Object -Property DisplayName, RoleDefinitionName, Scope
}

## New role assignment
$signName = 'robert.kucinski@also.com'
$scope = '/subscriptions/4933eec9-928e-4cca-8ce3-8f0ea0928d36'
$roleDefinition = 'Data Factory Contributor'
New-AzRoleAssignment -SignInName $signName -Scope $scope -RoleDefinitionName $roleDefinition | Select-Object -Property DisplayName, RoleDefinitionName, Scope

## Remove role assignments
$signName = 'maciej.sek@also.com'
$i = 0; $roleAssignments = Get-AzRoleAssignment -SignInName $signName | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name 'Id' -Value $i -PassThru; $i++ } | Select-Object Id, SignInName, RoleDefinitionName, Scope; $roleAssignments
# remove selected role assignments
$roleAssignments | Where-Object -Property Id -in (0) | ForEach-Object {
    Remove-AzRoleAssignment -Scope $_.Scope -SignInName $_.SignInName -RoleDefinitionName $_.RoleDefinitionName
}
# remove all role assignments
$roleAssignments | ForEach-Object {
    Write-Output $_.Scope
    Remove-AzRoleAssignment -Scope $_.Scope -SignInName $_.SignInName -RoleDefinitionName $_.RoleDefinitionName
}

<### Select Resource Groups where user should be added ###>
$signName = 'robert.kucinski@also.com'
# enumerate resource groups
$i = 0; $resGroups = Get-AzResourceGroup | Sort-Object -Property ResourceGroupName | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name 'Id' -Value $i -PassThru; $i++ } | Select-Object Id, ResourceGroupName, ResourceId
# enumerate existing assignments
$roleAssignments = Get-AzRoleAssignment -SignInName $signName
# check if user is already assigned to resource group
foreach ($group in $resGroups) {
    if ($null -ne ($roleAssignments | Where-Object { $_.Scope -eq $group.ResourceId })) {
        $group | Add-Member -MemberType NoteProperty -Name 'IsMember' -Value $true
    }
    else {
        $group | Add-Member -MemberType NoteProperty -Name 'IsMember' -Value $false
    }
}
$resGroups | Where-Object -Property IsMember -eq $false | Select-Object -Property Id, ResourceGroupName
$resGroups | Where-Object -Property Id -in (15, 16, 21, 27) | ForEach-Object {
    New-AzRoleAssignment -Scope $_.ResourceId -SignInName $signName -RoleDefinitionName 'Contributor'
}
