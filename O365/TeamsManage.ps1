<#
Update-Module MicrosoftTeams
Install-Module MicrosoftTeams -AllowClobber
Uninstall-Module MicrosoftTeams
Get-Command -Module MicrosoftTeams
Get-Help Add-TeamUser -examples
Get-TeamHelp
#>
# Get all commands for module MicrosoftTeams
# Connect to Microsoft Teams

Import-Module MicrosoftTeams
$account = (Connect-MicrosoftTeams).Account.Id

Get-Team -User $account | Format-Table -AutoSize -Property GroupId, DisplayName, Visibility, MailNickName

# Get list and count for teams
Get-Team | Sort-Object -Property DisplayName
(Get-Team).Count

Get-Team -User szymon.osiecki@abcdata.eu
Get-Team -User Szymon.Osiecki@also.com

Get-Team |
Sort-Object -Property DisplayName |
ForEach-Object {
    $currentTeam = $_.DisplayName; $GroupId = $_.GroupId
    Get-TeamUser -GroupId $_.GroupId -Role owner |
    Select-Object -Property @{Name = "GroupId"; Expression = { ($GroupId) } }, @{Name = "GroupName"; Expression = { ($currentTeam) } }, Name, User
    #        Format-Table -Property @{Name="GroupName";Expression={($currentTeam)}}, Name
}

$groupId = Get-Team -User $account | Where-Object { $_.DisplayName -eq 'IT_Management' } | Select-Object -ExpandProperty GroupId

Get-TeamUser -GroupId $groupId -Role owner
Get-TeamUser -GroupId $groupId | Select-Object Name, User, Role | Export-Csv -Path '.\.assets\export\team_itm_usersa.csv' -NoTypeInformation -Encoding ascii
Get-TeamUser -GroupId $groupId | Format-Table -AutoSize -Property Name, User, Role, UserId

# Add user to team
Add-TeamUser -GroupId $groupId -User $userName -Role Owner
Remove-TeamUser -GroupId $groupId -User $userName
Get-TeamUser -GroupId $groupId | Select-Object -Property Name, Role, User, UserId
Remove-Team -GroupId $groupId

# List teams to manage
$teamList = 'Wyprzedaze'

# Select listed teams from exported file
$selTeams = @()
foreach ($t in $teamList) {
    $selTeams += Import-Csv -Path '.\.assets\config\enumerateTeams.csv' |
    Where-Object { $_.MailNickName -eq $t } |
    Select-Object -Property GroupId, DisplayName, Visibility, MailNickName, Description
}

# Create selected teams
foreach ($st in $selTeams) {
    #$st = $selTeams[0]
    $newTeams = New-Team -DisplayName ('PL ' + $st.DisplayName) -Description $st.Description -Visibility $st.Visibility -MailNickName $st.MailNickName
}

# Get newly created teams
$newTeams = Get-Team -User $account | Where-Object { $_.MailNickName -in $teamList }

# Create teams channels
$teamChannels = Import-Csv -Path '.\.assets\config\enumerateTeamsChannels.csv'
foreach ($nt in $newTeams) {
    $tp = $teamChannels | Where-Object { ('PL ' + $_.GroupName) -eq $nt.DisplayName -and $_.DisplayName -ne 'General' }
    foreach ($channel in $tp) {
        Write-Output ('Group: ' + $nt.DisplayName + ' | Channel: ' + $channel.DisplayName)
        try {
            New-TeamChannel -GroupId $nt.GroupId -DisplayName $channel.DisplayName -Description $channel.Description
        }
        catch {
            Write-Warning ('Couldn''t create channel: ' + $channel.DisplayName + ' in group: ' + $nt.DisplayName)
        }
    }
}

# Create teams members
$teamMembers = Import-Csv -Path '.\.assets\config\enumerateTeamsMembers.csv' | Where-Object { $_.Role -ne 'guest' }
. 'functions\func_common.ps1' # required fo Set-Ascii function
$failedUser = @()
foreach ($nt in $newTeams) {
    #$nt = $newTeams[0]
    $tm = $teamMembers | Where-Object { ('PL ' + $_.GroupName) -eq $nt.DisplayName }
    foreach ($member in $tm) {
        #$member = $tm[2]
        $user = Set-Ascii -String (($member.Name -replace (' ', '.')) + '@also.com')
        try {
            Write-Output ($nt.DisplayName + ': ' + $user + ' | ' + $member.Role)
            Add-TeamUser -GroupId $nt.GroupId -User $user -Role $member.Role
        }
        catch {
            Write-Output ('Couldn''t add user: ' + $member.User + ' to group: ' + $nt.DisplayName)
            $failedUser += [PSCustomObject]@{
                User     = $member.User;
                UserName = $member.Name
                Role     = $member.Role
                Group    = $nt.DisplayName
                GroupId  = $nt.GroupId
                Error    = $error[0].Exception.Message
            }
        }
    }
}
# Save failed users
$failedUser | Export-Csv -Path '.\.assets\config\enumerateTeamsMembersFailed.csv'

## Add member from AD group to team
# Get members of the group
$memberNames = Get-ADGroupMember 'abcdevelopers' -Recursive | Where-Object { $_.objectclass -eq 'user' } | Select-Object -Property name
$memberNames.Count
# Get team
Get-Team -User $account | Format-Table -AutoSize -Property GroupId, DisplayName, Visibility, MailNickName
$team = Get-Team -User $account | Where-Object { $_.GroupId -eq '286f816f-7862-4fb1-84b9-3732b20cb486' }

$failedUser = @()
$addedUser = @()
foreach ($member in $memberNames) {
    #$member = $memberNames[2]
    $user = Set-Ascii -String (($member.Name -replace (' ', '.')) + '@also.com')
    try {
        Write-Output ($team.DisplayName + ': ' + $user)
        Add-TeamUser -GroupId $team.GroupId -User $user -Role 'member'
        $addedUser += $user
    }
    catch {
        Write-Output ('Couldn''t add user: ' + $member.User + ' to group: ' + $nt.DisplayName)
        $failedUser += [PSCustomObject]@{
            User     = $member.User;
            UserName = $member.Name
            Role     = $member.Role
            Group    = $team.DisplayName
            GroupId  = $team.GroupId
            Error    = $error[0].Exception.Message
        }
    }
}
# Save failed users
$failedUser | Export-Csv -Path '.\.assets\config\enumerateTeamsMembersFailed.csv'

Disconnect-MicrosoftTeams
