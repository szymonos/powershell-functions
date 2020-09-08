<#
.SYNOPSIS
https://docs.microsoft.com/en-us/powershell/module/Azuread/?view=azureadps-2.0

.DESCRIPTION
PowerShell 5.1 only
.NOTES
Find-Module -Name AzureAD
Install-Module -Name AzureADPreview
Uninstall-Module AzureAD -Force
Get-InstalledModule -Name AzureADPreview
.EXAMPLE
Azure\AzureADManage.ps1
#>
Import-Module AzureADPreview
Connect-AzureAD -Credential (Get-Secret 'Az')

## Get all AzureAD groups and display groups count
$adGroups = Get-AzureADGroup -Top 100000
$adGroups.Count

## Get all AzureAD Users
$users = Get-AzureADUser -Top 100000 | Select-Object -Property DisplayName, UserPrincipalName, UserType
$users.Count
($users | Where-Object -Property UserType -eq Member).Count
($users | Where-Object -Property UserType -eq Guest).Count

## Get all AzureAD groups beginning with 'PL '
Get-AzureADGroup -SearchString 'PL-' | Select-Object *

## Get all AzureAD groups where I'm the owner
$myGroups = @()
Get-AzureADGroup -Top 100000 | ForEach-Object {
    if ($null -ne (Get-AzureADGroupOwner -ObjectId $_.ObjectId | Where-Object -Property UserPrincipalName -eq 'Szymon.Osiecki@also.com')) {
        $myGroups += $_
    }
}
$myGroups

## Get all group members
$gMembers = foreach ($group in $myGroups) {
    Get-AzureADGroupMember -ObjectId $group.ObjectId | Select-Object -Property @{Name = 'Groupname'; Expression = { $group.DisplayName } }, DisplayName, UserType
}
$gMembers

## Get all group owners
$gOwners = foreach ($group in $myGroups) {
    Get-AzureADGroupOwner -ObjectId $group.ObjectId | Select-Object -Property @{Name = 'Groupname'; Expression = { $group.DisplayName } }, DisplayName, UserType
}
$gOwners

## Create new group
$groupName = 'PL Dev Azure Owners'; $nickName = $groupName.Replace(' ', '').Replace('-', '')
$aadGroup = New-AzureADGroup -DisplayName $groupName `
    -Description 'Azure subscriptions owners' `
    -MailEnabled $false `
    -SecurityEnabled $true `
    -MailNickName $nickName

# Add/verify group members/owners
$aadGroup = Get-AzureADGroup -SearchString 'PL Dev Scrum Team A'
$aadUser = Get-AzureADUser -ObjectId 'Krzysztof.Anusiewicz@also.com'
$aadUser = Get-AzureADUser -Filter "startswith(DisplayName,'maciej sek')"; $aadUser.DisplayName
Add-AzureADGroupMember -ObjectId $aadGroup.ObjectId -RefObjectId $aadUser.ObjectId
Get-AzureADGroupMember -ObjectId $aadGroup.ObjectId

Add-AzureADGroupOwner -ObjectId $aadGroup.ObjectId -RefObjectId $aadUser.ObjectId
Get-AzureADGroupOwner -ObjectId $aadGroup.ObjectId

# Find AAD user
Get-AzureADUser -Filter "startswith(DisplayName,'Grzegorz Pa')"
$userProps = 'ObjectId', 'ObjectType', 'AccountEnabled', 'DirSyncEnabled', 'DisplayName', 'GivenName', 'Surname', 'UserPrincipalName', 'MailNickName', 'UserType', 'PasswordPolicies'
Get-AzureADUser -ObjectId 'TestAADLink.PL@also.com' | Select-Object $userProps

## Get group information
Get-AzureADGroup -ObjectId $aadGroup.ObjectId

## Update group
$groupName = 'PL Dev Scrum Team 2'; $nickName = $groupName.Replace(' ', '').Replace('-', '')
$aadGroup = Get-AzureADGroup -SearchString $groupName
Set-AzureADGroup -ObjectId $aadGroup.ObjectId `
    -Description 'Members of Scrum Team 2 in PL Development Division'
#-MailNickName $nickName

## Remove group
Remove-AzureADGroup -ObjectId '02e2b2e8-a3e6-44fd-bb6d-ee3060ca51ca'

# Query AAD groups
Get-AzureADGroup -SearchString 'PL-SQL' | Select-Object ObjectId, DisplayName, MailNickName, Description
Get-AzureADGroup -SearchString 'PL Dev' | Select-Object DisplayName, SecurityEnabled, MailNickName, Description
Get-AzureADGroup -SearchString 'PL-SQLDEVProductionSupport' | Get-AzureADGroupMember
Get-AzureADGroup -SearchString 'PL-SQLDEVRead' | Get-AzureADGroupMember | Select-Object -Property ObjectId, ObjectType, DisplayName, UserPrincipalName

# Add/Remove member from group
$groupName = 'PL-SQLDEVRead';
$member = Get-AzureADUser -ObjectId 'TestAADLink.PL@also.com'   # Add/Remove user
$member = Get-AzureADGroup -SearchString  'PL-SQLAden'          # Add/Remove group
Get-AzureADGroup -SearchString $groupName | Remove-AzureADGroupMember -MemberId $member.ObjectId
Get-AzureADGroup -SearchString $groupName | Add-AzureADGroupMember -RefObjectId $member.ObjectId

# Remove all users from group
$srcGroup = 'PL-SQLDEVDbOwner'
$srcGroupMembers = Get-AzureADGroupMember -ObjectId (Get-AzureADGroup -SearchString $srcGroup).ObjectId | Where-Object -Property ObjectType -eq 'User'
foreach ($member in $srcGroupMembers) {
    Remove-AzureADGroupMember  -ObjectId $dstAadGroup.ObjectId -MemberId $member.ObjectId
}

# Copy group members from one group to another
$srcGroup = 'PL-SQLAden'
$dstGroup = 'PL-SQLDEVDbOwner'
$srcAadGroup = Get-AzureADGroup -SearchString $srcGroup
$srcGroupMembers = Get-AzureADGroupMember -ObjectId $srcAadGroup.ObjectId
$dstAadGroup = Get-AzureADGroup -SearchString $dstGroup
foreach ($member in $srcGroupMembers) {
    if (!(Get-AzureADGroupMember  -ObjectId $dstAadGroup.ObjectId | Where-Object -Property ObjectId -eq $member.ObjectId)) {
        Add-AzureADGroupMember -ObjectId $dstAadGroup.ObjectId -RefObjectId $member.ObjectId
        Write-Output ('- [' + $dstAadGroup.DisplayName + '] added user: ' + $member.DisplayName)
    } else {
        Write-Output ('- [' + $dstAadGroup.DisplayName + '] already exists user: ' + $member.DisplayName)
    }
}
Get-AzureADGroupMember -ObjectId $dstAadGroup.ObjectId

# Add application owner
Get-AzureADApplication  -Filter "startswith(DisplayName,'ALSO-ECom-InterLink-40911050-63d8-4d59-9d0e-f5f4f0e5a1d3')"
Get-AzureADApplication  -ObjectId 'a75d60d5-da59-46db-8d91-b7dafe63c4c6'
Add-AzureADApplicationOwner -ObjectId 'a75d60d5-da59-46db-8d91-b7dafe63c4c6' -RefObjectId $aadUser.ObjectId
