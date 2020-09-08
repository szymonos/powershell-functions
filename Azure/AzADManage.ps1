<#
.SYNOPSIS
Azure Active Directory manage with Az.Resources module commands
.NOTES
https://docs.microsoft.com/en-us/powershell/module/az.resources/?view=azps-3.7.0#active_directory
.EXAMPLE
Azure\AzADManage.ps1
#>

## Get all AzAD groups and display groups count
$adGroups = Get-AzADGroup -Top 100000
$adGroups.Count

## Get all AzAD Users
$users = Get-AzADUser -Top 100000 | Select-Object -Property DisplayName, UserPrincipalName, UserType
$users.Count
($users | Where-Object -Property UserType -eq Member).Count
($users | Where-Object -Property UserType -eq Guest).Count

## Get all AzAD groups beginning with 'PL '
Get-AzADGroup -SearchString 'PL-' | Select-Object *

## Get all AzAD groups where I'm the owner
$myGroups = @()
Get-AzADGroup -Top 100000 | ForEach-Object {
    if ($null -ne (Get-AzADGroupOwner -ObjectId $_.ObjectId | Where-Object -Property UserPrincipalName -eq 'Szymon.Osiecki@also.com')) {
        $myGroups += $_
    }
}
$myGroups

## Get all group members
$gMembers = foreach ($group in $myGroups) {
    Get-AzADGroupMember -ObjectId $group.ObjectId | Select-Object -Property @{Name = 'Groupname'; Expression = { $group.DisplayName } }, DisplayName, UserType
}
$gMembers

## Create new group
$aadGroup = New-AzADGroup -DisplayName 'PL Dev Scrum Team8 TeamLead ' `
    -Description 'Leader of Team8 in PL Development Division' `
    -MailNickName 'PL-DevScrumTeam8TeamLead'

# Add/verify group members/owners
$aadGroup = Get-AzADGroup -SearchString 'PL Dev Scrum Team8'
$aadUser = Get-AzADUser -ObjectId 'Katarzyna.Grabska@also.com'
Add-AzADGroupMember  -MemberObjectId $aadUser.Id -TargetGroupObjectId $aadGroup.Id
Get-AzADGroupMember -GroupObjectId $aadGroup.Id | Select-Object -Property Id, DisplayName, UserPrincipalName
Get-AzADGroupMember -GroupDisplayName 'PL Dev Scrum Team DevOps' | Select-Object -Property Id, DisplayName, UserPrincipalName

# Find AAD user
Get-AzADUser -StartsWith 'devscrum'
Get-AzADUser -ObjectId 'PL Dev Scrum Team8'

## Get group information
Get-AzADGroup -ObjectId $aadGroup.ObjectId

## Update group
Set-AzADGroup -ObjectId $aadGroup.ObjectId `
    -Description 'Group to access Azure SQL Databases with privileged permissions'

## Remove group
Remove-AzADGroup -DisplayName 'PL Dev Scrum Team8'

# Query AAD groups
Get-AzADGroup -DisplayNameStartsWith 'scrumte' | Select-Object -Property Id, DisplayName, SecurityEnabled, Description
Get-AzADGroup -DisplayNameStartsWith 'devscrum' | Select-Object -Property Id, DisplayName, SecurityEnabled, Description
Get-AzADGroup -DisplayNameStartsWith 'PL Dev' | Select-Object -Property Id, DisplayName, SecurityEnabled, Description
Get-AzADGroup -ObjectId 'ae6ffaf5-07b1-415d-be26-6b302310a0a9' | Select-Object -Property *
Get-AzADGroupMember -GroupDisplayName 'PL-SQLDEVRead' | Select-Object -Property Id, ObjectType, DisplayName, UserPrincipalName
Get-AzADGroupMember -GroupDisplayName 'PL-SQLDEVProductionSupport' | Select-Object -Property @{Name = 'Name'; Expression = {$_.DisplayName + " (" + $_.UserPrincipalName + ")"}}
Get-AzADGroupMember -GroupDisplayName 'PL-SQLGlobalAdmins' | Select-Object -Property @{Name = 'Name'; Expression = {$_.DisplayName + " (" + $_.UserPrincipalName + ")"}}
Get-AzADGroupMember -GroupObject $aadGroup | Select-Object -Property @{Name = 'Name'; Expression = {$_.DisplayName + " (" + $_.UserPrincipalName + ")"}}

# Add member to group
Add-AzADGroupMember -MemberUserPrincipalName 'Marcin.Cieslik@also.com' -TargetGroupDisplayName 'PL-SQLGlobalAdmins'
Add-AzADGroupMember -MemberUserPrincipalName 'Krzysztof.Kaluzynski@also.com' -TargetGroupObject $aadGroup

# Remove member from group
Remove-AzADGroupMember -MemberUserPrincipalName 'Dariusz.Swirdowski@also.com' -GroupDisplayName 'PL-SQLDEVProductionSupport'
Get-AzADGroup -DisplayNameStartsWith 'PL-SQLGlobalAdmins' | Add-AzADGroupMember -RefObjectId $aadUser.ObjectId

# Remove user list from the specfied group
$groupName = 'PL-SQLDEVRead'
$userList = 'Maciej.Sek@also.com', 'Terminated.Jaroslaw.Pyrz@also.com'
foreach ($user in $userList) {
    $user
    Remove-AzADGroupMember -MemberUserPrincipalName $user -GroupDisplayName $groupName -ErrorAction SilentlyContinue
}

# Copy group members from one group to another
$srcGroup = 'PL Developers'
$dstGroup = 'PL-SQLDEVDbOwner'
$srcAadGroup = Get-AzADGroup -SearchString $srcGroup
$srcGroupMembers = Get-AzADGroupMember -ObjectId $srcAadGroup.ObjectId
$dstAadGroup = Get-AzADGroup -SearchString $dstGroup
foreach ($member in $srcGroupMembers) {
    Add-AzADGroupMember -ObjectId $dstAadGroup.ObjectId -RefObjectId $member.ObjectId
}
Get-AzADGroupMember -ObjectId $dstAadGroup.ObjectId
